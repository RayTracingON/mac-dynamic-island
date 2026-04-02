import Foundation
import AppKit
import OSLog

struct UpdateMetadata: Codable {
    let latestVersion: String
    let minimumVersion: String?
    let releaseNotes: String
    let downloadUrl: String
    let releaseDate: String?
    let isMandatory: Bool?
}

final class UpdateChecker {
    static let shared = UpdateChecker()
    
    // Modern Logger API - avoids NSXPCDecoder format string issues
    private let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.maclingdonggao.overlay", category: "update")
    
    func checkForUpdates(metadataUrl: String, completion: @escaping (Result<UpdateMetadata?, Error>) -> Void) {
        guard let url = URL(string: metadataUrl) else {
            let error = NSError(domain: "UpdateChecker", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid metadata URL"])
            logger.error("Invalid metadata URL: \(metadataUrl)")
            completion(.failure(error))
            return
        }
        
        let session = URLSession.shared
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            defer { session.finishTasksAndInvalidate() }
            
            if let error = error {
                self?.logger.error("Network error fetching updates: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "UpdateChecker", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                completion(.failure(error))
                return
            }
            
            do {
                let metadata = try JSONDecoder().decode(UpdateMetadata.self, from: data)
                
                if self?.isNewerVersion(metadata.latestVersion) == true {
                    self?.logger.info("Update available: \(metadata.latestVersion)")
                    completion(.success(metadata))
                } else {
                    self?.logger.info("Already on latest version")
                    completion(.success(nil))
                }
            } catch {
                self?.logger.error("Failed to decode metadata: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func showUpdateAlert(metadata: UpdateMetadata, window: NSWindow? = nil) {
        let alert = NSAlert()
        alert.messageText = L("update.available_title")
        alert.informativeText = L("update.available_message", metadata.latestVersion)
        
        if !metadata.releaseNotes.isEmpty {
            alert.informativeText += "\n\n" + L("update.release_notes") + "\n" + metadata.releaseNotes
        }
        
        alert.addButton(withTitle: L("update.download"))
        alert.addButton(withTitle: L("update.remind_later"))
        alert.addButton(withTitle: L("button.skip"))
        
        alert.alertStyle = .informational
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn:
            if let url = URL(string: metadata.downloadUrl) {
                NSWorkspace.shared.open(url)
                logger.info("User initiated download")
            }
        case .alertSecondButtonReturn:
            logger.debug("User deferred update check")
        case .alertThirdButtonReturn:
            logger.debug("User skipped update")
        default:
            break
        }
    }
    
    func showNoUpdatesAlert() {
        let alert = NSAlert()
        alert.messageText = L("update.no_updates")
        alert.informativeText = L("update.current_version")
        alert.addButton(withTitle: L("button.ok"))
        alert.alertStyle = .informational
        _ = alert.runModal()
        
        logger.info("User checked for updates; already current")
    }
    
    func showUpdateErrorAlert(error: Error) {
        let alert = NSAlert()
        alert.messageText = L("update.error_title")
        alert.informativeText = L("update.error_message", error.localizedDescription)
        alert.addButton(withTitle: L("button.ok"))
        alert.alertStyle = .warning
        _ = alert.runModal()
        
        logger.error("Update check error: \(error.localizedDescription)")
    }
    
    private func isNewerVersion(_ remoteVersion: String) -> Bool {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        return compareVersions(remoteVersion, currentVersion) > 0
    }
    
    private func compareVersions(_ version1: String, _ version2: String) -> Int {
        let v1 = version1.split(separator: ".").compactMap { Int($0) }
        let v2 = version2.split(separator: ".").compactMap { Int($0) }
        
        for i in 0..<max(v1.count, v2.count) {
            let num1 = i < v1.count ? v1[i] : 0
            let num2 = i < v2.count ? v2[i] : 0
            
            if num1 > num2 { return 1 }
            if num1 < num2 { return -1 }
        }
        return 0
    }
}
