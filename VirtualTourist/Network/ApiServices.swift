//
//  ApiServices.swift
//  VirtualTourist
//
//  Created by Marcos Vinicius Goncalves Contente on 25/02/19.
//  Copyright © 2019 Marcos Vinicius Goncalves Contente. All rights reserved.
//

import Foundation
import UIKit

class ApiServices {
    
    var session = URLSession.shared
    private var tasks: [String: URLSessionDataTask] = [:]
    
    //MARK: Singleton
    class func shared() -> ApiServices {
        struct Singleton {
            static var shared = ApiServices()
        }
        return Singleton.shared
    }

    func displayImageFromFlickrBySearch(latitude: Double, longitude: Double, totalPages: Int?, completion: @escaping (_ result: FlickrPhotos?, _ error: Error?) -> Void) {
        
        // random pages
        var page: Int {
            if let totalPages = totalPages {
                let page = min(totalPages, 4000/Constants.FlickrParameterValues.PhotosPerPage)
                return Int(arc4random_uniform(UInt32(page)) + 1)
            } else {
                return 1
            }
        }
        
        let box = minMaxSize(latitude: latitude, longitude: longitude)
        
        let parameters = [
            Constants.FlickrParameterKeys.PhotosPerPage : "\(Constants.FlickrParameterValues.PhotosPerPage)",
            Constants.FlickrParameterKeys.NoJSONCallback : Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParameterKeys.BoundingBox : box,
            Constants.FlickrParameterKeys.SafeSearch : Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.APIKey : Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.Format : Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.Extras : Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Method : Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.Page : "\(page)"
        ]
        
        _ = getMethod(parameters: parameters) { (data, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            guard let data = data else {
                let userInfo = [NSLocalizedDescriptionKey : "Could not retrieve data."]
                completion(nil, NSError(domain: "getMethod", code: 1, userInfo: userInfo))
                return
            }
            
            do {
                let photosParser = try JSONDecoder().decode(FlickrPhotos.self, from: data)
                completion(photosParser, nil)
            } catch {
                print("\(#function) error: \(error)")
                completion(nil, error)
            }
        }
    }
    
    func downloadImage(imageUrl: String, result: @escaping (_ result: Data?, _ error: NSError?) -> Void) {
        guard let url = URL(string: imageUrl) else {
            return
        }
        let task = getMethod(nil, url, parameters: [:]) { (data, error) in
            result(data, error)
            self.tasks.removeValue(forKey: imageUrl)
        }
        
        if tasks[imageUrl] == nil {
            tasks[imageUrl] = task
        }
    }
    
    func cancelDownload(_ imageUrl: String) {
        tasks[imageUrl]?.cancel()
        if tasks.removeValue(forKey: imageUrl) != nil {
            print("\(#function) task canceled: \(imageUrl)")
        }
    }
    
    // MARK: getMethod
    func getMethod(
        _ method : String? = nil,
        _ customUrl : URL? = nil,
        parameters : [String: String],
        completionHandlerForGET: @escaping (_ result: Data?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        let request: NSMutableURLRequest!
        if let customUrl = customUrl {
            request = NSMutableURLRequest(url: customUrl)
        } else {
            request = NSMutableURLRequest(url: buildURLFromParameters(parameters, withPathExtension: method))
        }
        
        showActivityIndicator(true)
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                self.showActivityIndicator(false)
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(nil, NSError(domain: "getMethod", code: 1, userInfo: userInfo))
            }
            
            if let error = error {
                
                if (error as NSError).code == URLError.cancelled.rawValue {
                    completionHandlerForGET(nil, nil)
                } else {
                    sendError("Error with request: \(error.localizedDescription)")
                }
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Wrong status code")
                return
            }
            
            guard let data = data else {
                sendError("No data returned upon request!")
                return
            }
            
            self.showActivityIndicator(false)
            completionHandlerForGET(data, nil)
            
        }
        
        task.resume()
        
        return task
    }
    
    
    private func buildURLFromParameters(_ parameters: [String: String], withPathExtension: String? = nil) -> URL {
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath + (withPathExtension ?? "")
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: value)
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    private func minMaxSize(latitude: Double, longitude: Double) -> String {
        //Minimum and maximum boundaries
        let minLongitude = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minLatitude = max(latitude  - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maxLongitude = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maxLatitude = min(latitude  + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minLongitude),\(minLatitude),\(maxLongitude),\(maxLatitude)"
    }
    
    // Show|Hide activity indicator.
    private func showActivityIndicator(_ show: Bool) {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = show
        }
    }
}
