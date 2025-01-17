//
//  NetworkService.swift
//  NoteBlocks App
//
//  Created by Deyan on 16.01.25.
//

import Foundation

import Foundation

struct NetworkService {
    static let shared = NetworkService()

    private init() {} // Prevent direct initialization

    func fetchNotes(userId: Int, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let url = URL(string: "http://192.168.0.222/project/API/fetch.php") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "user_id=\(userId)"
        request.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            // Log the raw response for debugging
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw response: \(rawResponse)")
            }

            // Remove any non-JSON content before attempting to parse
            if let responseString = String(data: data, encoding: .utf8) {
                // Assuming the JSON starts after the first closing brace or curly bracket
                if let range = responseString.range(of: "{") {
                    let jsonString = responseString[range.lowerBound...]
                    if let jsonData = jsonString.data(using: .utf8) {
                        do {
                            // Now attempt to parse the cleaned JSON data
                            let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
                            guard json != nil else {
                                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
                            }

                            completion(.success(json!))
                        } catch {
                            completion(.failure(error))
                        }
                    } else {
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert response string to data"])))
                    }
                }
            }
        }.resume()
    }
}




