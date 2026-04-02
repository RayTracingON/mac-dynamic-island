import Foundation

extension URLSession {
    /// Async data task with Result
    func dataTask(with url: URL) async throws -> (Data, URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            let task = dataTask(with: url) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data, let response = response {
                    continuation.resume(returning: (data, response))
                } else {
                    continuation.resume(throwing: URLError(.unknown))
                }
            }
            task.resume()
        }
    }
    
    /// Async data task with URLRequest
    func dataTask(with request: URLRequest) async throws -> (Data, URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            let task = dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data, let response = response {
                    continuation.resume(returning: (data, response))
                } else {
                    continuation.resume(throwing: URLError(.unknown))
                }
            }
            task.resume()
        }
    }
    
    /// Download file from URL
    func downloadFile(from url: URL, to destination: URL, progress: ((Double) -> Void)? = nil) async throws {
        let (tempURL, response) = try await download(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        try FileManager.default.moveItem(at: tempURL, to: destination)
    }
    
    /// Fetch JSON from URL
    func fetchJSON<T: Decodable>(from url: URL, type: T.Type) async throws -> T {
        let (data, _) = try await dataTask(with: url)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    /// Post JSON to URL
    func postJSON<T: Encodable>(_ value: T, to url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(value)
        
        let (data, response) = try await dataTask(with: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return data
    }
}

// MARK: - URLRequest Extensions

extension URLRequest {
    /// Create request with headers
    static func withHeaders(_ headers: [String: String], url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        return request
    }
    
    /// Create POST request with JSON body
    static func postJSON<T: Encodable>(_ value: T, to url: URL) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(value)
        
        return request
    }
}
