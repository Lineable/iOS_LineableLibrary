//
//  LineableHTTP.swift
//  LineableExample
//
//  Created by Berrymelon on 2/17/16.
//  Copyright © 2016 Lineable. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import CoreBluetooth

#if DEBUG
let kBASEURL = "https://dev.lineable.net"
let kACCOUNTURL = "http://dev.lineable.net:9090"
let kDETECTURL = "http://dev.lineable.net:8099"
let kAWSTOKEN = "https://dev.lineable.net/log/getToken"
#else
let kBASEURL = "https://apiv2.lineable.net"
let kACCOUNTURL = "https://account.lineable.net"
let kDETECTURL = "https://detect.lineable.net"
let kAWSTOKEN = "https://apiv2.lineable.net/log/getToken"
#endif

protocol LineableHTTP {}

enum LineableHTTPEncodingType {
    case JSON
    case URL
}

private extension NSMutableURLRequest {
    func setBodyContent(contentMap: Dictionary<String, AnyObject>) {
        var firstOneAdded = false
        var contentBodyAsString = String()
        let contentKeys:Array<String> = Array(contentMap.keys)
        for contentKey in contentKeys {
            let value = "\(contentMap[contentKey]!)"
            
            if(!firstOneAdded) {
                contentBodyAsString = contentBodyAsString + contentKey + "=" + value
                firstOneAdded = true
            }
            else {
                contentBodyAsString = contentBodyAsString + "&" + contentKey + "=" + value
            }
        }
        contentBodyAsString = contentBodyAsString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        self.HTTPBody = contentBodyAsString.dataUsingEncoding(NSUTF8StringEncoding)
    }
}

extension LineableHTTP {
    
    private func escape(string: String) -> String {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        let allowedCharacterSet = NSCharacterSet.URLQueryAllowedCharacterSet().mutableCopy() as! NSMutableCharacterSet
        allowedCharacterSet.removeCharactersInString(generalDelimitersToEncode + subDelimitersToEncode)
        
        var escaped = ""
        
        if #available(iOS 8.3, OSX 10.10, *) {
            escaped = string.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacterSet) ?? string
        } else {
            let batchSize = 50
            var index = string.startIndex
            
            while index != string.endIndex {
                let startIndex = index
                let endIndex = index.advancedBy(batchSize, limit: string.endIndex)
                let range = Range(start: startIndex, end: endIndex)
                
                let substring = string.substringWithRange(range)
                
                escaped += substring.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacterSet) ?? substring
                
                index = endIndex
            }
        }
        
        return escaped
    }
    
    private func queryComponents(key: String, _ value: AnyObject) -> [(String, String)] {
        var components: [(String, String)] = []
        
        if let dictionary = value as? [String: AnyObject] {
            for (nestedKey, value) in dictionary {
                components += queryComponents("\(key)[\(nestedKey)]", value)
            }
        } else if let array = value as? [AnyObject] {
            for value in array {
                components += queryComponents("\(key)[]", value)
            }
        } else {
            components.append((escape(key), escape("\(value)")))
        }
        
        return components
    }
    
    private func encodedRequest(encoding:LineableHTTPEncodingType,request:NSMutableURLRequest,parameters:[String:AnyObject]?) -> NSMutableURLRequest {

        guard let parameters = parameters else { return request }
        
        var mutableURLRequest = request
        var encodingError: NSError? = nil
        
        switch encoding {
        case .URL:
            func query(parameters: [String: AnyObject]) -> String {
                var components: [(String, String)] = []
                
                for key in parameters.keys.sort(<) {
                    let value = parameters[key]!
                    components += queryComponents(key, value)
                }
                
                return (components.map { "\($0)=\($1)" } as [String]).joinWithSeparator("&")
            }
            
            if let
                URLComponents = NSURLComponents(URL: mutableURLRequest.URL!, resolvingAgainstBaseURL: false)
                where !parameters.isEmpty
            {
                let percentEncodedQuery = (URLComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + query(parameters)
                URLComponents.percentEncodedQuery = percentEncodedQuery
                mutableURLRequest.URL = URLComponents.URL
            }
        case .JSON:
            do {
                let options = NSJSONWritingOptions()
                let data = try NSJSONSerialization.dataWithJSONObject(parameters, options: options)
                
                mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                mutableURLRequest.HTTPBody = data
            } catch {
                encodingError = error as NSError
            }
        }
        
        return mutableURLRequest
    }
    
    func sendData(type:String,url:String,encoding:LineableHTTPEncodingType,params:[String:AnyObject]?,completion:(result:Int,info:AnyObject?)->()) {
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfig.timeoutIntervalForResource = 45
        
        let session = NSURLSession(configuration: sessionConfig)
        
        let postsEndpoint: String = url
        var postsUrlRequest = NSMutableURLRequest(URL: NSURL(string: postsEndpoint)!)
        postsUrlRequest.HTTPMethod = type
        
        let bundleID = NSBundle.mainBundle().bundleIdentifier != nil ? NSBundle.mainBundle().bundleIdentifier! : "unvalidBundleID"
        let bundleVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as! String
        var defaultHeaders = [String:String]()
        defaultHeaders["User-Agent"] = "iOS \(bundleID) \(UIDevice.currentDevice().systemVersion) \(bundleVersion)"
        defaultHeaders["version_code"] = bundleVersion
        defaultHeaders["phone_type"] = "1"
        defaultHeaders["push_type"] = "APNS"
        defaultHeaders["phone_model"] = UIDevice.currentDevice().modelName
        
        for (headerField, headerValue) in defaultHeaders {
            postsUrlRequest.addValue(headerValue, forHTTPHeaderField: headerField)
        }
        
        if let headers = LineableDetector.sharedDetector.user?.httpHeaders() {
            for (headerField, headerValue) in headers {
                postsUrlRequest.addValue(headerValue, forHTTPHeaderField: headerField)
            }
        }
        
        postsUrlRequest = self.encodedRequest(encoding, request: postsUrlRequest, parameters: params)
        
        let task = session.dataTaskWithRequest(postsUrlRequest, completionHandler: {
            (data, response, error) -> Void in
            
            guard let data = data else { return }
            do {
                let result = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                    as! NSDictionary
                
                guard let resultCode = result["result"]!.integerValue else {
                    completion(result: 1009, info: nil)
                    return
                }
                
                completion(result: resultCode, info: result["info"])
                
            } catch _ {
                completion(result: 1009, info: nil)
            }
        })
        
        task.resume()
        
    }
    
}
