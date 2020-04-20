//
//  LDService.swift
//
//  Created by Lazar on 12/12/16.
//  Copyright © 2017 Lazar. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import AlamofireNetworkActivityIndicator
import Reachability
import LDMainFramework

public enum ResponseType
{
    case TypeJSON
    case TypeData
    case TypeString
}

public class LDService: NSObject {
    
    open var reachability : Reachability! = nil
    
    var mySessionManager: Session!
    public var internetOn : Bool = true
    
    public init(timeoutIntervalRequest: Double = 30, timeoutIntervalResource: Double = 30, contentType: String = "application/json") {
        super.init()
        
        var defaultHeaders = URLSessionConfiguration.default.headers
        defaultHeaders["Content-Type"] = contentType
        
        let configuration = URLSessionConfiguration.default
        configuration.headers = defaultHeaders
        
        configuration.timeoutIntervalForRequest = timeoutIntervalRequest
        configuration.timeoutIntervalForResource = timeoutIntervalResource
        
        mySessionManager = Alamofire.Session(configuration: configuration)
        
        NetworkActivityIndicatorManager.shared.isEnabled = true
        
        setupReachability()
        
    }
    
    /// Setup Reachability function
    open func setupReachability()
    {
        reachability = try! Reachability()
        
        internetOn = reachability.connection != .unavailable
        
        reachability.whenReachable = { reachability in
            DispatchQueue.main.async() {
                if reachability.connection == .wifi {
                    print("Reachable via WiFi")
                } else {
                    print("Reachable via Cellular")
                }
                self.internetOn = true;
                LDAppNotify.postNotification("internetOn")
            }
        }
        reachability.whenUnreachable = { reachability in
            DispatchQueue.main.async() {
                print("Not reachable")
                self.internetOn = false;
                LDAppNotify.postNotification("internetOff")
            }
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    
    /// Function to send request to server
    ///
    /// - Parameters:
    ///   - strURL: First param is URL.
    ///   - path: Path param is appended to URL
    ///   - methodType: HTTP Method. Can be .post, .get, .put...
    ///   - params: Parameters that you send as post values
    ///   - header: Additional headers that are not included in session manager
    ///   - responseType: Select do you want JSON,Data or String response type. Default value is JSON type.
    ///   - encoding: Select encoding type. Default is URLEncoding
    ///   - sendUnauthorized: set true to post Unauthorized notification in case of unauthorized error
    ///   - unauthorizedCode: HTTP status code for unauthorized error
    ///   - success: Success function
    ///   - failure: Failure function
    
    open func requestWithURL(_ strURL: String, path: String, methodType: Alamofire.HTTPMethod, params: [String : AnyObject]?, header: [String : String]?, responseType:ResponseType = .TypeJSON, encoding: ParameterEncoding = URLEncoding.default, sendUnauthorized:Bool = true, unauthorizedCode:Int = 401, success:@escaping(Any) -> Void, failure:@escaping(Any?,Int) -> Void)
    {
        var targetUrl = strURL+path
        targetUrl = targetUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        let url = NSURL(string: targetUrl)
        
        if url == nil {
            failure(nil, -1)
            return
        }
        let urlComponents = URLComponents(url: url! as URL, resolvingAgainstBaseURL: true)!
                
        mySessionManager.request(urlComponents as URLConvertible, method: methodType, parameters: params, encoding: encoding, headers: header == nil ? nil : HTTPHeaders(header!), interceptor: nil, requestModifier: nil)
            .responseJSON { responseObject in
                if responseType != .TypeJSON
                {
                    return
                }
                if responseObject.response?.statusCode == unauthorizedCode
                {
                    failure(responseObject.data as Any, unauthorizedCode)
                    if sendUnauthorized
                    {
                        LDAppNotify.postNotification("Unauthorized")
                    }
                    return
                }

                switch responseObject.result {
                    case .success(_):
                    if responseObject.response?.statusCode == 200 {
                        success(responseObject.data as Any)
                    }
                    case let .failure(error):
                        print(error.localizedDescription)
                        failure(nil,0)
                }
                
                if responseObject.response?.statusCode != 200 {
                    let statusCode = responseObject.response?.statusCode
                    JSONParser.parseError(JSONData: responseObject.data)
                    failure(responseObject.data as Any, statusCode!)
                }
                

            } .responseString { (responseObject) -> Void in
                if responseType != .TypeString
                {
                    return
                }
                print("****** responseString ******")
                print(responseObject)
                
            } .responseData { (responseObject) -> Void in
                if responseType != .TypeData
                {
                    return
                }
                if responseObject.response?.statusCode == unauthorizedCode
                {
                    failure(responseObject.data as Any, unauthorizedCode)
                    if sendUnauthorized
                    {
                        LDAppNotify.postNotification("Unauthorized")
                    }
                    return
                }
                
                switch responseObject.result {
                    case .success(_):
                        if responseObject.response?.statusCode == 200 {
                            success(responseObject.data as Any)
                    }
                    case let .failure(error):
                        print(error.localizedDescription)
                        failure(nil,0)
                }
                
                if responseObject.response?.statusCode != 200 {
                    let statusCode = responseObject.response?.statusCode
                    JSONParser.parseError(JSONData: responseObject.data)
                    failure(responseObject.data as Any, statusCode!)
                }

            }
    }
    
    /// Function to upload multiple images to server.
    ///
    /// - Parameters:
    ///   - strURL: First param is URL.
    ///   - path: Path param is appended to URL
    ///   - images: Array of images where key is param name and value is UIImage. Images are sent to server as JPEG Or PNG
    ///   - videos: Array of videos where key is param name and value is Video URL. Images are sent to server as MP4
    ///   - params: Parameters that you send as post values
    ///   - header: Additional headers that are not included in session manager
    ///   - JPEGcompression: quality for JPEG image
    ///   - sendAsPNG: send image as PNG
    ///   - sendUnauthorized: set true to post Unauthorized notification in case of unauthorized error
    ///   - unauthorizedCode: HTTP status code for unauthorized error
    ///   - success: Success function
    ///   - failure: Failure function
    open func mediaUploadWithURL(_ strURL: String, path: String, images:[String : UIImage] = [:], videos:[String : URL] = [:], params: [String : String]?, header: [String : String]?, JPEGcompression: CGFloat = 0.7, sendAsPNG: Bool = false, sendUnauthorized:Bool = true, unauthorizedCode:Int = 401, success:@escaping(Any) -> Void, failure:@escaping (Any?,Int) -> Void)
    {
        let request = try! URLRequest(url:strURL+path, method: .post, headers:header == nil ? nil : HTTPHeaders(header!))
         
        mySessionManager.upload(multipartFormData: { (multipartFormData) in
            
            for image in images {
                if sendAsPNG
                {
                    let fileData = image.value.pngData()!
                    multipartFormData.append(fileData, withName: image.key, fileName: "name", mimeType: "image/png")
                } else {
                    let fileData = image.value.jpegData(compressionQuality: JPEGcompression)!
                    multipartFormData.append(fileData, withName: image.key, fileName: "name", mimeType: "image/jpeg")
                }
            }
            
            for video in videos {
                if let videoData = NSData(contentsOf: video.value) {
                    multipartFormData.append(videoData as Data, withName: video.key, fileName: "name", mimeType: "video/quicktime")
                }
            }
            
            for (key, value) in params! {
                multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
            }
        }, with: request as URLRequestConvertible).responseJSON(completionHandler: { responseObject in
            
            if responseObject.response?.statusCode == unauthorizedCode
            {
                failure(responseObject.data as Any, unauthorizedCode)
                if sendUnauthorized
                {
                    LDAppNotify.postNotification("Unauthorized")
                }
                return
            }
            
            switch responseObject.result {
                case .success(_):
                    if responseObject.response?.statusCode == 200 {
                        success(responseObject.data as Any)
                }
                case let .failure(error):
                    print(error.localizedDescription)
                    failure(nil,0)
            }
            
            if responseObject.response?.statusCode != 200 {
                let statusCode = responseObject.response?.statusCode
                JSONParser.parseError(JSONData: responseObject.data)
                failure(responseObject.data as Any, statusCode!)
            }
            
        }).uploadProgress(queue: .main, closure: { progress in
            print("Upload Progress: \(progress.fractionCompleted)")
        })
    }
}
