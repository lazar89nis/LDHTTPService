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
    
    open var token : String = ""
    open var reachability : Reachability! = nil
    
    open static var mySessionMenager: SessionManager! = nil
    open static var internetOn : Bool = true
    
    open static var timeoutIntervalRequest:TimeInterval = 30
    open static var timeoutIntervalResource:TimeInterval = 30
    open static var contentType = "application/json"
    
    open static let shared: LDService = {
    
        let instance = LDService()
        
        var defaultHeaders = Alamofire.SessionManager.defaultHTTPHeaders
        defaultHeaders["Content-Type"] = contentType
        
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = defaultHeaders
        
        configuration.timeoutIntervalForRequest = timeoutIntervalRequest
        configuration.timeoutIntervalForResource = timeoutIntervalResource
        
        mySessionMenager = Alamofire.SessionManager(configuration: configuration)
    
        NetworkActivityIndicatorManager.shared.isEnabled = true
        
        instance.setupReachability()
        
        return instance
    }()
    
    /// Setup Reachability function
    open func setupReachability()
    {
        reachability = Reachability()!
        
        reachability.whenReachable = { reachability in
            DispatchQueue.main.async() {
                if reachability.connection == .wifi {
                    print("Reachable via WiFi")
                } else {
                    print("Reachable via Cellular")
                }
                LDService.internetOn = true;
                LDAppNotify.postNotification("internetOn")
            }
        }
        reachability.whenUnreachable = { reachability in
            DispatchQueue.main.async() {
                print("Not reachable")
                LDService.internetOn = false;
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
    ///   - header: Additional heders that are not included in session menager
    ///   - responseType: Select do you want JSON,Data or String response type. Default value is JSON type.
    ///   - success: Success function
    ///   - failure: Failure function
    open func requestWithURL(_ strURL: String, path: String, methodType: Alamofire.HTTPMethod, params: [String : AnyObject]?, header: [String : String]?, responseType:ResponseType = .TypeJSON, success:@escaping(Any) -> Void, failure:@escaping(Any?,Int) -> Void)
    {
        LDService.mySessionMenager.request(strURL+path, method:methodType, parameters:params, headers:header)
            .responseJSON { (responseObject) -> Void in
                if responseType != .TypeJSON
                {
                    return
                }
                if responseObject.response?.statusCode == 401
                {
                    LDAppNotify.postNotification("Unauthorized")
                    return
                }
                
                if responseObject.result.isSuccess && responseObject.response?.statusCode == 200 {
                    success(responseObject.data as Any)
                } else if responseObject.result.isFailure {
                    let error : Error = responseObject.result.error!
                    print(error.localizedDescription)
                    failure(nil,0)
                } else if responseObject.response?.statusCode != 200 {
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
                if responseObject.response?.statusCode == 401
                {
                    LDAppNotify.postNotification("Unauthorized")
                    return
                }
                
                if responseObject.result.isSuccess && responseObject.response?.statusCode == 200 {
                    success(responseObject.data as Any)
                } else if responseObject.result.isFailure {
                    let error : Error = responseObject.result.error!
                    print(error.localizedDescription)
                    failure(nil,0)
                } else if responseObject.response?.statusCode != 200 {
                    let statusCode = responseObject.response?.statusCode
                    
                    JSONParser.parseError(JSONData: responseObject.data)
                    
                    failure(responseObject.data as Any, statusCode!)
                }
                
            } /*.response { (responseObject) -> Void in
                print("response")
        }*/
    }
    
    /// Function to upload multiple images to server.
    ///
    /// - Parameters:
    ///   - strURL: First param is URL.
    ///   - path: Path param is appended to URL
    ///   - images: Array of images where key is param name and value is UIImage. Images are sent to server as JPEG Or PNG
    ///   - videos: Array of videos where key is param name and value is Video URL. Images are sent to server as MP4
    ///   - params: Parameters that you send as post values
    ///   - header: Additional heders that are not included in session menager
    ///   - success: Success function
    ///   - failure: Failure function
    open func mediaUploadWithURL(_ strURL: String, path: String, images:[String : UIImage] = [:], videos:[String : URL] = [:], params: [String : String]?, header: [String : String]?, JPEGcompression: CGFloat = 0.7, sendAsPNG: Bool = false, success:@escaping(Any) -> Void, failure:@escaping (Any?,Int) -> Void)
    {
        let request = try! URLRequest(url:strURL+path, method: .post, headers:header)
        
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            
            for image in images {
                if sendAsPNG
                {
                    let fileData = UIImagePNGRepresentation(image.value)!
                    multipartFormData.append(fileData, withName: image.key, fileName: "name", mimeType: "image/png")
                } else {
                    let fileData = UIImageJPEGRepresentation(image.value, JPEGcompression)!
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
        }, with: request, encodingCompletion: { (result) in
            
            switch result {
            case .success(let upload, _, _):
                upload.responseJSON { response in
                    
                    if response.result.isFailure
                    {
                        let error : Error = response.result.error!
                        print(error.localizedDescription)
                        failure(nil,0)
                    } else if response.response?.statusCode == 200
                    {
                        success(response.data as Any)
                    } else {
                        let statusCode = response.response?.statusCode
                        failure(response.data,statusCode!)
                    }
                }
            case .failure( _):
                failure(nil,0)
            }
            
        })
    }
}