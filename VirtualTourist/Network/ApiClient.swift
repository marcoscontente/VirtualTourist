//
//  ApiClient.swift
//  VirtualTourist
//
//  Created by Marcos Vinicius Goncalves Contente on 25/02/19.
//  Copyright © 2019 Marcos Vinicius Goncalves Contente. All rights reserved.
//

import Foundation

class ApiClient {
    
    var session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func makeRequest(with url: URL, method: String? = "GET", parameters: [String: String], headers: [String: String]? = [:], completion: @escaping (Data?, URLSessionTask.TaskError?) -> Void) -> URLSessionDataTask {
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = parameters.map { URLQueryItem(name: $0, value: $1) }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("", forHTTPHeaderField: "")
        request.addValue("", forHTTPHeaderField: "")
        
        return session.dataTask(with: request) { data, response, error in
            guard error == nil, let data = data else {
                completion(nil, .connection)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                completion(nil, .serverResponse)
                return
            }
            completion(data, nil)
        }
    }
}

extension URLSessionTask {
    
    // Describing the general kind of errors
    enum TaskError: Error {
        case connection
        case serverResponse
        case invalidJsonResponse
    }
}
