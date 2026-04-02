#if !APP_STORE
import Foundation
import Cocoa
import Combine

// MARK: - MediaRemote Dynamic Loading
// MediaRemote is a private framework - we load it dynamically at runtime

private class MediaRemoteBridge {
    static let shared = MediaRemoteBridge()
    
    private var handle: UnsafeMutableRawPointer?
    private(set) var isAvailable: Bool = false
    
    // Function pointers
    private var registerForNotifications: (@convention(c) (DispatchQueue) -> Void)?
    private var unregisterForNotifications: (@convention(c) () -> Void)?
    private var getNowPlayingInfo: (@convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void)?
    private var getIsPlaying: (@convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void)?
    private var getNowPlayingClient: (@convention(c) (DispatchQueue, @escaping (AnyObject?) -> Void) -> Void)?
    private var getClientBundleID: (@convention(c) (AnyObject?) -> UnsafePointer<CChar>?)?
    private var sendCommand: (@convention(c) (Int32, CFDictionary?) -> Bool)?
    
    private init() {
        loadFramework()
    }
    
    private func loadFramework() {
        let frameworkPath = "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote"
        handle = dlopen(frameworkPath, RTLD_NOW)
        
        guard handle != nil else {
            print("MediaRemote framework not available")
            isAvailable = false
            return
        }
        
        // Load function pointers
        registerForNotifications = unsafeBitCast(
            dlsym(handle, "MRMediaRemoteRegisterForNowPlayingNotifications"),
            to: (@convention(c) (DispatchQueue) -> Void)?.self
        )
        
        unregisterForNotifications = unsafeBitCast(
            dlsym(handle, "MRMediaRemoteUnregisterForNowPlayingNotifications"),
            to: (@convention(c) () -> Void)?.self
        )
        
        sendCommand = unsafeBitCast(
            dlsym(handle, "MRMediaRemoteSendCommand"),
            to: (@convention(c) (Int32, CFDictionary?) -> Bool)?.self
        )
        
        isAvailable = (registerForNotifications != nil)
    }
    
    func register(queue: DispatchQueue) {
        registerForNotifications?(queue)
    }
    
    func unregister() {
        unregisterForNotifications?()
    }
    
    func sendCommand(_ command: Int, options: [String: Any]?) -> Bool {
        return sendCommand?(Int32(command), options as CFDictionary?) ?? false
    }
    
    deinit {
        if let handle = handle {
            dlclose(handle)
        }
    }
}

// MediaRemote commands
enum MRCommand: Int {
    case play = 0
    case pause = 1
    case togglePlayPause = 2
    case stop = 3
    case nextTrack = 4
    case previousTrack = 5
    case toggleShuffle = 6
    case toggleRepeat = 7
    case changePlaybackPosition = 45
    case changePlaybackRate = 46
}

// MediaRemote info keys
struct MRMediaRemoteKeys {
    static let title = "kMRMediaRemoteNowPlayingInfoTitle"
    static let artist = "kMRMediaRemoteNowPlayingInfoArtist"
    static let album = "kMRMediaRemoteNowPlayingInfoAlbum"
    static let duration = "kMRMediaRemoteNowPlayingInfoDuration"
    static let elapsed = "kMRMediaRemoteNowPlayingInfoElapsedTime"
    static let playbackRate = "kMRMediaRemoteNowPlayingInfoPlaybackRate"
    static let artwork = "kMRMediaRemoteNowPlayingInfoArtworkData"
    static let timestamp = "kMRMediaRemoteNowPlayingInfoTimestamp"
}

/// Controller for system-wide Now Playing info using MediaRemote framework
/// Supports any app that uses the system media controls (Safari, Chrome, Firefox, etc.)
class NowPlayingController: MediaControllerProtocol {
    static let shared = NowPlayingController()
    
    var name: String = "NowPlaying"
    var playbackState: PlaybackState = .empty
    
    // MediaControllerProtocol requirements
    var isRunning: Bool {
        return currentBundleID != nil && !playbackState.title.isEmpty
    }
    var supportsPlaybackControl: Bool { true }
    var supportsSeek: Bool { true }
    var supportsRepeat: Bool { true }
    var supportsShuffle: Bool { true }
    var supportsFavorite: Bool { false }
    var supportsVolume: Bool { false }
    var bundleIdentifier: String { currentBundleID ?? "" }
    
    private var updateTimer: Timer?
    private let queue = DispatchQueue(label: "com.mac.notch.nowplaying")
    private var lastNowPlayingInfo: [String: Any] = [:]
    private var currentBundleID: String?
    
    private init() {}
    
    deinit {
        stop()
    }
    
    // MARK: - Lifecycle
    
    func start(onChange: @escaping (PlaybackState) -> Void) {
        // Register for Now Playing notifications
        MediaRemoteBridge.shared.register(queue: queue)
        
        // Listen for changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNowPlayingInfoChanged),
            name: NSNotification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNowPlayingApplicationChanged),
            name: NSNotification.Name("kMRMediaRemoteNowPlayingApplicationDidChangeNotification"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlaybackStateChanged),
            name: NSNotification.Name("kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification"),
            object: nil
        )
        
        // Start periodic updates for elapsed time
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
        
        // Initial fetch
        fetchNowPlayingInfo()
    }
    
    func stop() {
        MediaRemoteBridge.shared.unregister()
        NotificationCenter.default.removeObserver(self)
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - Notification Handlers
    
    @objc private func handleNowPlayingInfoChanged(_ notification: Notification) {
        fetchNowPlayingInfo()
    }
    
    @objc private func handleNowPlayingApplicationChanged(_ notification: Notification) {
        fetchCurrentApplication()
        fetchNowPlayingInfo()
    }
    
    @objc private func handlePlaybackStateChanged(_ notification: Notification) {
        updatePlaybackState()
    }
    
    // MARK: - Data Fetching
    
    private func fetchNowPlayingInfo() {
        // MediaRemote info fetching disabled - use AppleScript fallback in NowPlayingManager
    }
    
    private func fetchCurrentApplication() {
        // MediaRemote client fetching disabled - use AppleScript fallback in NowPlayingManager
    }
    
    private func updatePlaybackState() {
        // MediaRemote state fetching disabled - use AppleScript fallback in NowPlayingManager
    }
    
    private func updatePlaybackStateFromInfo(_ info: [String: Any]) {
        var newState = PlaybackState()
        
        // Extract basic info
        newState.title = info[MRMediaRemoteKeys.title] as? String ?? ""
        newState.artist = info[MRMediaRemoteKeys.artist] as? String ?? ""
        newState.album = info[MRMediaRemoteKeys.album] as? String ?? ""
        
        // Extract timing info
        if let duration = info[MRMediaRemoteKeys.duration] as? Double {
            newState.duration = duration
        }
        
        if let elapsed = info[MRMediaRemoteKeys.elapsed] as? Double {
            newState.position = elapsed
        }
        
        // Extract playback rate (0 = paused, 1 = playing)
        if let rate = info[MRMediaRemoteKeys.playbackRate] as? Double {
            newState.isPlaying = rate > 0
        }
        
        // Extract artwork
        if let artworkData = info[MRMediaRemoteKeys.artwork] as? Data {
            newState.albumArt = NSImage(data: artworkData)
        }
        
        // Store timestamp for elapsed time calculation
        if let timestamp = info[MRMediaRemoteKeys.timestamp] as? Date {
            newState.lastUpdateTime = timestamp
        }
        
        // Set application name
        if let bundleID = currentBundleID {
            newState.appName = applicationName(from: bundleID)
        }
        
        playbackState = newState
    }
    
    private func updateElapsedTime() {
        guard playbackState.isPlaying,
              playbackState.duration > 0,
              let lastUpdate = playbackState.lastUpdateTime else {
            return
        }
        
        // Calculate elapsed time based on when we last got an update
        let timeSinceUpdate = Date().timeIntervalSince(lastUpdate)
        let newPosition = playbackState.position + timeSinceUpdate
        
        // Don't exceed duration
        if newPosition <= playbackState.duration {
            playbackState.position = newPosition
            playbackState.lastUpdateTime = Date()
        }
    }
    
    // MARK: - Playback Control
    
    func togglePlayPause() {
        _ = MediaRemoteBridge.shared.sendCommand(MRCommand.togglePlayPause.rawValue, options: nil)
    }
    
    func play() {
        _ = MediaRemoteBridge.shared.sendCommand(MRCommand.play.rawValue, options: nil)
    }
    
    func pause() {
        _ = MediaRemoteBridge.shared.sendCommand(MRCommand.pause.rawValue, options: nil)
    }
    
    func nextTrack() {
        _ = MediaRemoteBridge.shared.sendCommand(MRCommand.nextTrack.rawValue, options: nil)
    }
    
    func previousTrack() {
        _ = MediaRemoteBridge.shared.sendCommand(MRCommand.previousTrack.rawValue, options: nil)
    }
    
    func seek(to position: TimeInterval) {
        let options = ["kMRMediaRemoteOptionPlaybackPosition": position]
        _ = MediaRemoteBridge.shared.sendCommand(MRCommand.changePlaybackPosition.rawValue, options: options)
    }
    
    func setVolume(_ volume: Double) {
        // Volume control not available through MediaRemote
        // Use system volume instead
    }
    
    func getVolume() async -> Double {
        return 0.5
    }
    
    // MARK: - Extended Controls
    
    func toggleShuffle() {
        _ = MediaRemoteBridge.shared.sendCommand(MRCommand.toggleShuffle.rawValue, options: nil)
    }
    
    func toggleRepeat() {
        _ = MediaRemoteBridge.shared.sendCommand(MRCommand.toggleRepeat.rawValue, options: nil)
    }
    
    func toggleFavorite() {
        // Like functionality not available through MediaRemote
        // App-specific implementation required
    }
    
    func stopPlayback() {
        _ = MediaRemoteBridge.shared.sendCommand(MRCommand.stop.rawValue, options: nil)
    }
    
    func openMusicApp() {
        guard let bundleID = currentBundleID else { return }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        }
    }
    
    func getCurrentState() async -> PlaybackState {
        return playbackState
    }
    
    // MARK: - Helpers
    
    private func applicationName(from bundleID: String) -> String {
        // Common bundle ID to name mappings
        let knownApps: [String: String] = [
            "com.apple.Safari": "Safari",
            "com.google.Chrome": "Chrome",
            "org.mozilla.firefox": "Firefox",
            "com.microsoft.edgemac": "Edge",
            "com.brave.Browser": "Brave",
            "com.operasoftware.Opera": "Opera",
            "com.apple.Music": "Music",
            "com.spotify.client": "Spotify",
            "com.apple.TV": "TV",
            "com.apple.podcasts": "Podcasts",
            "com.colliderli.iina": "IINA",
            "org.videolan.vlc": "VLC"
        ]
        
        if let name = knownApps[bundleID] {
            return name
        }
        
        // Try to get name from bundle
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
           let bundle = Bundle(url: url),
           let name = bundle.infoDictionary?["CFBundleName"] as? String {
            return name
        }
        
        // Fallback to bundle ID
        return bundleID.components(separatedBy: ".").last?.capitalized ?? "Unknown"
    }
    
    // MARK: - State Queries
    
    var currentTrackInfo: String {
        guard !playbackState.title.isEmpty else {
            return "No media playing"
        }
        
        if !playbackState.artist.isEmpty {
            return "\(playbackState.title) - \(playbackState.artist)"
        }
        
        return playbackState.title
    }
}
#endif
