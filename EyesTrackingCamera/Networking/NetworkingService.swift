//
//  NetworkingService.swift
//  EyesTrackingCamera
//
//  Created by user on 22.03.2024.
//

import Foundation
import UIKit

class NetworkingService {
    private struct Constant  {
        static let clientID = "80b53ac31d3068b"
        static  let url = "https://api.imgur.com/3/image"
    }
    
    func uploadImage(_ image: UIImage, completion: @escaping (Result<Bool,Error>) -> Void) {
        guard let imageProperties = ImageProperties(withImage: image, froKey: "image") else { return }
        guard let url = URL(string: Constant.url) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        let request = getConfiguredRequest(form: url, with: imageProperties.data)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(error ?? NSError(domain: "Unknown Error", code: 0, userInfo: nil)))
                return
            }
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let data = jsonResponse["data"] as? [String: Any],
                   let _ = data["link"] as? String {
                    print (jsonResponse)
                    completion(.success(true))
                } else {
                    completion(.failure(NSError(domain: "Invalid Response", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func getConfiguredRequest(form url: URL, with imageData: Data) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.setValue("Client-ID \(Constant.clientID)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        let contentType = "multipart/form-data; boundary=\(boundary)"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.png\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        return request
    }
}
