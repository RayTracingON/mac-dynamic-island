import Foundation
import Combine

/// Manager for handling file downloads
class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()
    
    @Published var activeDownloads: [String: DownloadTask] = [:]
    
    private var session: URLSession!
    private var downloadTasks: [URLSessionTask: String] = [:]
    
    private override init() {
        super.init()
        
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    // MARK: - Download
    
    func download(from url: URL, to destination: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        let task = session.downloadTask(with: url)
        let identifier = UUID().uuidString
        
        let downloadTask = DownloadTask(
            id: identifier,
            url: url,
            destination: destination,
            progress: 0,
            completion: completion
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.activeDownloads[identifier] = downloadTask
        }
        
        downloadTasks[task] = identifier
        task.resume()
    }
    
    func cancelDownload(_ identifier: String) {
        guard let task = downloadTasks.first(where: { $0.value == identifier })?.key else {
            return
        }
        
        task.cancel()
        
        DispatchQueue.main.async { [weak self] in
            self?.activeDownloads.removeValue(forKey: identifier)
        }
    }
    
    func cancelAll() {
        session.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.activeDownloads.removeAll()
        }
    }
}

// MARK: - URLSession Delegate

extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let identifier = downloadTasks[downloadTask],
              let download = activeDownloads[identifier] else {
            return
        }
        
        do {
            // Move file to destination
            if FileManager.default.fileExists(atPath: download.destination.path) {
                try FileManager.default.removeItem(at: download.destination)
            }
            
            try FileManager.default.moveItem(at: location, to: download.destination)
            
            DispatchQueue.main.async { [weak self] in
                download.completion(.success(download.destination))
                self?.activeDownloads.removeValue(forKey: identifier)
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                download.completion(.failure(error))
                self?.activeDownloads.removeValue(forKey: identifier)
            }
        }
        
        downloadTasks.removeValue(forKey: downloadTask)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let identifier = downloadTasks[downloadTask] else {
            return
        }
        
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        
        DispatchQueue.main.async { [weak self] in
            self?.activeDownloads[identifier]?.progress = progress
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error,
           let identifier = downloadTasks[task as! URLSessionDownloadTask] {
            DispatchQueue.main.async { [weak self] in
                self?.activeDownloads[identifier]?.completion(.failure(error))
                self?.activeDownloads.removeValue(forKey: identifier)
            }
            
            downloadTasks.removeValue(forKey: task)
        }
    }
}

// MARK: - Models

class DownloadTask: ObservableObject {
    let id: String
    let url: URL
    let destination: URL
    @Published var progress: Double
    let completion: (Result<URL, Error>) -> Void
    
    init(id: String, url: URL, destination: URL, progress: Double, completion: @escaping (Result<URL, Error>) -> Void) {
        self.id = id
        self.url = url
        self.destination = destination
        self.progress = progress
        self.completion = completion
    }
}
