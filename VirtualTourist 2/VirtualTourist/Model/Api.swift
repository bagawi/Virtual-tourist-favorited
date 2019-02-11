//
//  Api.swift
//  VirtualTourist
//
//  Created by Mohammed Albaqawi on 1/20/19.
//  Copyright © 2019 Mohd. All rights reserved.
//

import Foundation

class Api {
    public  var count = 1
    
    func bringPhotos (latitude: Double , longitude: Double, _ complition: @escaping (_ result : Bool, _ photoInfo: [PhotoParse], _ err: String?) -> Void) {
     
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: self.bboxString(latitude: latitude, longitude: longitude),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParameterKeys.PhotosPerPage  : Constants.FlickrParameterValues.PhotosPerPage,
            Constants.FlickrParameterKeys.Page  : count
            ] as [String : Any]
        var methodParametersWithPageNumber = methodParameters
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        count += 1
        methodParametersWithPageNumber[Constants.FlickrParameterKeys.Page] = count
        for (key, value) in methodParametersWithPageNumber  {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        var url = components.url!
        var request = NSMutableURLRequest(url: url)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
         //   print("data is ",String(data: data!, encoding: .utf8)!)
            func displayError(_ error: String) {
                print(error)

            }
         
            guard (error == nil) else {
                displayError("There was an error with your request: \(error)")
                return
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            do {
                let  decoder = JSONDecoder()
                let object = try decoder.decode(Flicker.self, from: data)
                let photoInfo = object.photos.photo
                print("object is",object.photos.perpage)
                
                DispatchQueue.main.async {
                    
                    complition(true,photoInfo,nil)
                }
            }catch let err {
                print("Error", err)
            }
        }
        
        task.resume()
    }
    
    private func bboxString(latitude: Double, longitude: Double) -> String {
        
        let minimumLon = max(longitude - Api.Constants.Flickr.SearchBBoxHalfWidth, Api.Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Api.Constants.Flickr.SearchBBoxHalfHeight, Api.Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Api.Constants.Flickr.SearchBBoxHalfWidth, Api.Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Api.Constants.Flickr.SearchBBoxHalfHeight, Api.Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        
    }
    class func sharedInstance() -> Api {
        struct Singleton {
            static var sharedInstance = Api()
        }
        return Singleton.sharedInstance
    }
    
}


