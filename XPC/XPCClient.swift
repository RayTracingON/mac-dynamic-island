import Foundation

/// Client for communicating with XPC helper service
class XPCClient {
    static let shared = XPCClient()
    
    private var connection: NSXPCConnection?
    private let helperIdentifier = "com.mac灵动岛.helper"
    
    private init() {
        setupConnection()
    }
    
    deinit {
        connection?.invalidate()
    }
    
    // MARK: - Connection Setup
    
    private func setupConnection() {
        connection = NSXPCConnection(machServiceName: helperIdentifier, options: .privileged)
        
        let interface = NSXPCInterface(with: XPCHelperProtocol.self)
        
        // SECURITY FIX: Prevent insecure decode warnings (NSXPCDecoder)
        let classes: [AnyClass] = [
            NSString.self, NSNumber.self, NSDictionary.self, NSArray.self, 
            NSDate.self, NSData.self, NSURL.self
        ]
        let allowedClasses = NSSet(array: classes) as! Set<AnyHashable>
        
        // Explicitly whitelist classes for return values in reply blocks
        let selectorMap: [Selector] = [
            #selector(XPCHelperProtocol.getSystemInfo(completion:)),
            #selector(XPCHelperProtocol.checkPermissions(completion:)),
            #selector(XPCHelperProtocol.currentKeyboardBrightness(completion:)),
            #selector(XPCHelperProtocol.currentScreenBrightness(completion:))
        ]
        
        for selector in selectorMap {
            interface.setClasses(allowedClasses, for: selector, argumentIndex: 0, ofReply: true)
        }
        
        connection?.remoteObjectInterface = interface
        
        connection?.invalidationHandler = { [weak self] in
            print("XPC connection invalidated")
            self?.connection = nil
        }
        
        connection?.interruptionHandler = { [weak self] in
            print("XPC connection interrupted")
            self?.reconnect()
        }
        
        connection?.resume()
    }
    
    private func reconnect() {
        connection?.invalidate()
        connection = nil
        setupConnection()
    }
    
    // MARK: - Helper Interface
    
    private func getHelper() -> XPCHelperProtocol? {
        guard let connection = connection else {
            setupConnection()
            return nil
        }
        
        return connection.remoteObjectProxyWithErrorHandler { error in
            print("XPC error: \(error)")
        } as? XPCHelperProtocol
    }
    
    // MARK: - Health Check
    
    func ping(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let helper = getHelper() else {
            completion(.failure(XPCHelperError.connectionFailed))
            return
        }
        
        helper.ping { isRunning in
            completion(.success(isRunning))
        }
    }
    
    func checkStatus(completion: @escaping (XPCHelperStatus) -> Void) {
        ping { result in
            switch result {
            case .success(let isRunning):
                completion(isRunning ? .running : .installed)
            case .failure(let error):
                completion(.error(error))
            }
        }
    }
    
    // MARK: - System Info
    
    func getSystemInfo(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let helper = getHelper() else {
            completion(.failure(XPCHelperError.connectionFailed))
            return
        }
        
        helper.getSystemInfo { info in
            completion(.success(info))
        }
    }
    
    // MARK: - Task Execution
    
    func execute(command: String, arguments: [String], completion: @escaping (Result<(Int32, String, String), Error>) -> Void) {
        guard let helper = getHelper() else {
            completion(.failure(XPCHelperError.connectionFailed))
            return
        }
        
        helper.executePrivilegedTask(command, arguments: arguments) { exitCode, stdout, stderr in
            completion(.success((exitCode, stdout, stderr)))
        }
    }
    
    // MARK: - Monitoring
    
    func startMonitoring(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let helper = getHelper() else {
            completion(.failure(XPCHelperError.connectionFailed))
            return
        }
        
        helper.startMonitoring { success in
            completion(.success(success))
        }
    }
    
    func stopMonitoring(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let helper = getHelper() else {
            completion(.failure(XPCHelperError.connectionFailed))
            return
        }
        
        helper.stopMonitoring { success in
            completion(.success(success))
        }
    }
    
    // MARK: - File Operations
    
    func copyFile(from source: String, to destination: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let helper = getHelper() else {
            completion(.failure(XPCHelperError.connectionFailed))
            return
        }
        
        helper.copyFile(from: source, to: destination) { success, error in
            if success {
                completion(.success(()))
            } else {
                completion(.failure(XPCHelperError.taskFailed(reason: error ?? "Unknown error")))
            }
        }
    }
    
    func moveFile(from source: String, to destination: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let helper = getHelper() else {
            completion(.failure(XPCHelperError.connectionFailed))
            return
        }
        
        helper.moveFile(from: source, to: destination) { success, error in
            if success {
                completion(.success(()))
            } else {
                completion(.failure(XPCHelperError.taskFailed(reason: error ?? "Unknown error")))
            }
        }
    }
    
    func deleteFile(at path: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let helper = getHelper() else {
            completion(.failure(XPCHelperError.connectionFailed))
            return
        }
        
        helper.deleteFile(at: path) { success, error in
            if success {
                completion(.success(()))
            } else {
                completion(.failure(XPCHelperError.taskFailed(reason: error ?? "Unknown error")))
            }
        }
    }
    
    // MARK: - Permissions
    
    func requestAccessibilityPermissions(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let helper = getHelper() else {
            completion(.failure(XPCHelperError.connectionFailed))
            return
        }
        
        helper.requestAccessibilityPermissions { granted in
            completion(.success(granted))
        }
    }
    
    func checkPermissions(completion: @escaping (Result<[String: Bool], Error>) -> Void) {
        guard let helper = getHelper() else {
            completion(.failure(XPCHelperError.connectionFailed))
            return
        }
        
        helper.checkPermissions { permissions in
            completion(.success(permissions))
        }
    }
}
