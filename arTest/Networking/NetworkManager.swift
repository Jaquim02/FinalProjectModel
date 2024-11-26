import Foundation
import UIKit

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
    case serverError(String)
}

class NetworkManager {
    static let shared = NetworkManager()
    private let serverURL = "http://192.168.100.10:5001/recognize_digits"

    private init() {}
    
    func uploadImage(_ image: UIImage) async throws -> [Int] {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NetworkError.invalidData
        }
        
        guard let url = URL(string: serverURL) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add image data to the request body
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        if !(200...299).contains(httpResponse.statusCode) {
            if let errorMessage = String(data: data, encoding: .utf8) {
                throw NetworkError.serverError(errorMessage)
            } else {
                throw NetworkError.invalidResponse
            }
        }

        
        let decoder = JSONDecoder()
        let result = try decoder.decode([Int].self, from: data)
        return result
    }
} 
