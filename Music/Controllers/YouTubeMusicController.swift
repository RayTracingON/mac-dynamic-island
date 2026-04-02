import Foundation
import Cocoa
import Combine

/// Controller for YouTube Music Desktop App
/// Communicates via WebSocket server that runs in the YT Music companion app
class YouTubeMusicController: NSObject, MediaControllerProtocol, URLSessionWebSocketDelegate {
    static let shared = YouTubeMusicController()
    
    var name: String = "YouTube Music"
    var playbackState: PlaybackState = .empty
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var updateTimer: Timer?
    private var reconnectTimer: Timer?
    
    private let defaultPort = 9863
    private var currentPort = 9863
    private let maxReconnectAttempts = 5
    private var reconnectAttempts = 0
    
    private var isConnected = false
    
    private override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    deinit {
        stop()
    }
    
    // MARK: - MediaControllerProtocol Requirements
    
    var isRunning: Bool { isConnected }
    var bundleIdentifier: String { "com.google.YouTubeMusic" }
    
    func start(onChange: @escaping (PlaybackState) -> Void) {
        connect()
        
        // Periodic state updates
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.fetchCurrentState()
        }
    }
    
    func stop() {
        disconnect()
        updateTimer?.invalidate()
        updateTimer = nil
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    // MARK: - WebSocket Connection
    
    private func connect() {
        guard let url = URL(string: "ws://localhost:\(currentPort)") else { return }
        
        webSocketTask = session?.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Start listening for messages
        receiveMessage()
        
        // Send initial state request
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.fetchCurrentState()
        }
    }
    
    private func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
    }
    
    private func reconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            print("YouTubeMusicController: Max reconnect attempts reached")
            return
        }
        
        reconnectAttempts += 1
        print("YouTubeMusicController: Reconnecting (attempt \(reconnectAttempts)/\(maxReconnectAttempts))")
        
        disconnect()
        
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.connect()
        }
    }
    
    // MARK: - WebSocket Message Handling
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                self.handleMessage(message)
                self.receiveMessage() // Continue listening
                
            case .failure(let error):
                print("YouTubeMusicController: WebSocket error: \(error)")
                self.isConnected = false
                self.reconnect()
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            parseStateUpdate(text)
            
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                parseStateUpdate(text)
            }
            
        @unknown default:
            break
        }
    }
    
    private func sendCommand(_ command: String, parameters: [String: Any]? = nil) {
        var commandDict: [String: Any] = ["command": command]
        
        if let params = parameters {
            commandDict["parameters"] = params
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: commandDict),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        
        let message = URLSessionWebSocketTask.Message.string(jsonString)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("YouTubeMusicController: Send error: \(error)")
            }
        }
    }
    
    // MARK: - State Parsing
    
    private func parseStateUpdate(_ json: String) {
        guard let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.updatePlaybackState(from: dict)
        }
    }
    
    private func updatePlaybackState(from dict: [String: Any]) {
        isConnected = true
        reconnectAttempts = 0
        
        var newState = PlaybackState()
        
        // Track info
        if let track = dict["track"] as? [String: Any] {
            newState.title = track["title"] as? String ?? ""
            newState.artist = track["artist"] as? String ?? ""
            newState.album = track["album"] as? String ?? ""
            
            // Artwork URL
            if let artworkURL = track["cover"] as? String {
                loadArtwork(from: artworkURL) { [weak self] image in
                    DispatchQueue.main.async {
                        self?.playbackState.albumArt = image
                    }
                }
            }
        }
        
        // Player state
        if let player = dict["player"] as? [String: Any] {
            newState.isPlaying = player["isPaused"] as? Bool == false
            
            if let duration = player["trackDuration"] as? Double {
                newState.duration = duration
            }
            
            if let position = player["trackPosition"] as? Double {
                newState.position = position
            }
            
            if let volume = player["volumePercent"] as? Int {
                newState.volume = Double(volume) / 100.0
            }
            
            // Shuffle and repeat
            if let repeatMode = player["repeatType"] as? String {
                switch repeatMode {
                case "NONE":
                    newState.repeatMode = .off
                case "ONE":
                    newState.repeatMode = .one
                case "ALL":
                    newState.repeatMode = .all
                default:
                    newState.repeatMode = .off
                }
            }
            
            newState.isShuffled = player["shuffle"] as? Bool ?? false
            
            // Like status (map to isFavorite)
            if let likeStatus = player["likeStatus"] as? String {
                newState.isFavorite = likeStatus == "LIKE"
            }
        }
        
        newState.appName = "YouTube Music"
        newState.lastUpdateTime = Date()
        
        playbackState = newState
    }
    
    // MARK: - HTTP API Calls
    
    private func fetchCurrentState() {
        guard let url = URL(string: "http://localhost:\(currentPort)/query") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 2.0
        
        session?.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data,
                  let json = String(data: data, encoding: .utf8) else {
                return
            }
            
            self?.parseStateUpdate(json)
        }.resume()
    }
    
    private func loadArtwork(from urlString: String, completion: @escaping (NSImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        session?.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let image = NSImage(data: data) else {
                completion(nil)
                return
            }
            completion(image)
        }.resume()
    }
    
    // MARK: - Playback Control
    
    func togglePlayPause() {
        sendCommand("track-play-pause")
    }
    
    func play() {
        if !playbackState.isPlaying {
            sendCommand("track-play-pause")
        }
    }
    
    func pause() {
        if playbackState.isPlaying {
            sendCommand("track-play-pause")
        }
    }
    
    func nextTrack() {
        sendCommand("track-next")
    }
    
    func previousTrack() {
        sendCommand("track-previous")
    }
    
    func seek(to position: TimeInterval) {
        sendCommand("player-seek-to", parameters: ["seconds": position])
    }
    
    func setVolume(_ volume: Double) {
        let volumePercent = Int(volume * 100)
        sendCommand("player-set-volume", parameters: ["volume": volumePercent])
    }
    
    // MARK: - Extended Controls
    
    func toggleShuffle() {
        sendCommand("player-shuffle")
    }
    
    func toggleRepeat() {
        // Cycle through repeat modes: off -> all -> one -> off
        sendCommand("player-repeat")
    }
    
    func toggleFavorite() {
        sendCommand("track-thumbs-up")
    }
    
    func getVolume() async -> Double {
        return playbackState.volume
    }
    
    func getCurrentState() async -> PlaybackState {
        return playbackState
    }
    
    func openMusicApp() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.google.YouTubeMusic") {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        } else {
            // Try to open in browser
            NSWorkspace.shared.open(URL(string: "https://music.youtube.com")!)
        }
    }
    
    // MARK: - Additional Features
    
    func searchTrack(query: String) {
        sendCommand("player-search", parameters: ["query": query])
    }
    
    func thumbsDown() {
        sendCommand("track-thumbs-down")
    }
    
    func openLyrics() {
        sendCommand("player-show-lyrics")
    }
    
    // MARK: - URLSessionWebSocketDelegate
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("YouTubeMusicController: WebSocket connected")
        isConnected = true
        reconnectAttempts = 0
        fetchCurrentState()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("YouTubeMusicController: WebSocket closed")
        isConnected = false
        reconnect()
    }
    
    
    var currentTrackInfo: String {
        guard !playbackState.title.isEmpty else {
            return "Not connected to YouTube Music"
        }
        
        if !playbackState.artist.isEmpty {
            return "\(playbackState.title) - \(playbackState.artist)"
        }
        
        return playbackState.title
    }
}
