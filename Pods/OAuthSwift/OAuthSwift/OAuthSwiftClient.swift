//
//  OAuthSwiftClient.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation
import Accounts

var dataEncoding: NSStringEncoding = NSUTF8StringEncoding

public class OAuthSwiftClient {
    
    struct OAuth {
        static let version = "1.0"
        static let signatureMethod = "HMAC-SHA1"
    }
    
    private(set) public var credential: OAuthSwiftCredential
    
    public init(consumerKey: String, consumerSecret: String) {
        self.credential = OAuthSwiftCredential(consumer_key: consumerKey, consumer_secret: consumerSecret)
    }
    
    public init(consumerKey: String, consumerSecret: String, accessToken: String, accessTokenSecret: String) {
        self.credential = OAuthSwiftCredential(oauth_token: accessToken, oauth_token_secret: accessTokenSecret)
        self.credential.consumer_key = consumerKey
        self.credential.consumer_secret = consumerSecret
    }
    
    public func get(urlString: String, parameters: Dictionary<String, AnyObject>, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        self.request(urlString, method: "GET", parameters: parameters, success: success, failure: failure)
    }
    
    public func post(urlString: String, parameters: Dictionary<String, AnyObject>, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        self.request(urlString, method: "POST", parameters: parameters, success: success, failure: failure)
    }

    public func put(urlString: String, parameters: Dictionary<String, AnyObject>, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        self.request(urlString, method: "PUT", parameters: parameters, success: success, failure: failure)
    }

    public func delete(urlString: String, parameters: Dictionary<String, AnyObject>, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        self.request(urlString, method: "DELETE", parameters: parameters, success: success, failure: failure)
    }

    public func patch(urlString: String, parameters: Dictionary<String, AnyObject>, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        self.request(urlString, method: "PATCH", parameters: parameters, success: success, failure: failure)
    }

    func request(url: String, method: String, parameters: Dictionary<String, AnyObject>, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        
        if NSURL(string: url) == nil {
            print(url)
        }
        
        var url = NSURL(string: url)
        
        
        if self.credential.oauth2 {
            if var string = url!.relativeString {
                if string.hasPrefix("https://api.instagram.com/v1/") {
                    string += "?access_token=\(self.credential.oauth_token)"
                    url = NSURL(string: string)
                } else if string.hasPrefix("https://api.soundcloud.com/") {
                    var me = false
                    if string.hasSuffix("/me") {
                        me = true
                    }
                    string += "?client_id=\(self.credential.consumer_key)"
                    if me {
                        string += "&oauth_token=\(self.credential.oauth_token)"
                    } else {
                        string += "&access_token=\(self.credential.oauth_token)"
                    }
                    url = NSURL(string: string)
                }
            }
        }
        
        let request = OAuthSwiftHTTPRequest(URL: url!, method: method, parameters: parameters)
        if request.URL.absoluteString != "https://api.soundcloud.com/oauth2/token" {
            if self.credential.oauth2 {
                request.headers = ["Authorization": "Bearer \(self.credential.oauth_token)"]
            } else {
                request.headers = ["Authorization": OAuthSwiftClient.authorizationHeaderForMethod(method, url: url!, parameters: parameters, credential: self.credential)]
            }
        }
        request.successHandler = success
        request.failureHandler = failure
        request.dataEncoding = dataEncoding
        request.encodeParameters = true
        request.start()
    }
    
    public func postImage(urlString: String, parameters: Dictionary<String, AnyObject>, image: NSData, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        self.multiPartRequest(urlString, method: "POST", parameters: parameters, image: image, success: success, failure: failure, videoKey: nil)
    }
    
    public func multiPartRequest(url: String, method: String, parameters: Dictionary<String, AnyObject>, image: NSData, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?, videoKey: String?) {
        
        if let url = NSURL(string: url) {
            
            let request = OAuthSwiftHTTPRequest(URL: url, method: method, parameters: parameters)
            
            if self.credential.oauth2 {
                request.headers = ["Authorization": "Bearer \(self.credential.oauth_token)"]
            } else {
                request.headers = ["Authorization": OAuthSwiftClient.authorizationHeaderForMethod(method, url: url, parameters: parameters, credential: self.credential)]
            }
            
            request.successHandler = success
            request.failureHandler = failure
            request.dataEncoding = dataEncoding
            request.encodeParameters = true
            
            var parmaImage = [String: AnyObject]()
            if videoKey != nil {
                parmaImage[videoKey!] = image
            } else {
                parmaImage["media"] = image
            }
            let boundary = "AS-boundary-\(arc4random())-\(arc4random())"
            let type = "multipart/form-data; boundary=\(boundary)"
            let body = self.multiPartBodyFromParams(parmaImage, boundary: boundary)
            request.HTTPBodyMultipart = body
            request.contentTypeMultipart = type
            request.start()
        }
        
    }
    
    public func multiPartBodyFromParams(parameters: [String: AnyObject], boundary: String) -> NSData {
        let data = NSMutableData()
        
        let prefixData = "--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)
        let seperData = "\r\n".dataUsingEncoding(NSUTF8StringEncoding)
        
        for (key, value) in parameters {
            var sectionData: NSData?
            var sectionType: String?
            var sectionFilename = ""
            
            if key == "media" {
                let multiData = value as! NSData
                sectionData = multiData
                sectionType = "image/jpeg"
                sectionFilename = " filename=\"file\""
            } else if key == "source" {
                let multiData = value as! NSData
                sectionData = multiData
                sectionType = "video/mp4"
                sectionFilename = " filename=\"file.mp4\""
            } else {
                sectionData = "\(value)".dataUsingEncoding(NSUTF8StringEncoding)
            }
            
            data.appendData(prefixData!)
            
            if key == "media" {
                let sectionDisposition = "Content-Disposition: form-data; name=\"media\";\(sectionFilename)\r\n".dataUsingEncoding(NSUTF8StringEncoding)
                data.appendData(sectionDisposition!)
            } else if key == "source" {
                let sectionDisposition = "Content-Disposition: form-data; name=\"source\";\(sectionFilename)\r\n".dataUsingEncoding(NSUTF8StringEncoding)
                data.appendData(sectionDisposition!)
            }
            
            if let type = sectionType {
                let contentType = "Content-Type: \(type)\r\n".dataUsingEncoding(NSUTF8StringEncoding)
                data.appendData(contentType!)
            }
            
            // append data
            data.appendData(seperData!)
            data.appendData(sectionData!)
            data.appendData(seperData!)
            
        }
        
        data.appendData("--\(boundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        return data
    }

    public func postMultiPartRequest(url: String, method: String, parameters: Dictionary<String, AnyObject>, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        if let url = NSURL(string: url) {
            let request = OAuthSwiftHTTPRequest(URL: url, method: method, parameters: parameters)
            request.successHandler = success
            request.failureHandler = failure
            request.dataEncoding = dataEncoding
            request.encodeParameters = true

            if self.credential.oauth2 {
                request.headers = ["Authorization": "Bearer \(self.credential.oauth_token)"]
            } else {
                request.headers = ["Authorization": OAuthSwiftClient.authorizationHeaderForMethod(method, url: url, parameters: parameters, credential: self.credential)]
            }
            
            let boundary = "POST-boundary-\(arc4random())-\(arc4random())"
            let type = "multipart/form-data; boundary=\(boundary)"
            let body = self.multiDataFromObject(parameters, boundary: boundary)

            request.HTTPBodyMultipart = body
            request.contentTypeMultipart = type
            request.start()
        }
    }

    func multiDataFromObject(object: [String:AnyObject], boundary: String) -> NSData? {
        let data = NSMutableData()

        let prefixString = "--\(boundary)\r\n"
        let prefixData = prefixString.dataUsingEncoding(NSUTF8StringEncoding)!

        let seperatorString = "\r\n"
        let seperatorData = seperatorString.dataUsingEncoding(NSUTF8StringEncoding)!

        for (key, value) in object {

            var valueData: NSData?
            let filenameClause = ""

            let stringValue = "\(value)"
            valueData = stringValue.dataUsingEncoding(NSUTF8StringEncoding)!

            if valueData == nil {
                continue
            }
            data.appendData(prefixData)
            let contentDispositionString = "Content-Disposition: form-data; name=\"\(key)\";\(filenameClause)\r\n"
            let contentDispositionData = contentDispositionString.dataUsingEncoding(NSUTF8StringEncoding)
            data.appendData(contentDispositionData!)
            data.appendData(seperatorData)
            data.appendData(valueData!)
            data.appendData(seperatorData)
        }

        let endingString = "--\(boundary)--\r\n"
        let endingData = endingString.dataUsingEncoding(NSUTF8StringEncoding)!
        data.appendData(endingData)

        return data
    }

    public class func authorizationHeaderForMethod(method: String, url: NSURL, parameters: Dictionary<String, AnyObject>, credential: OAuthSwiftCredential) -> String {
        var authorizationParameters = Dictionary<String, AnyObject>()
        authorizationParameters["oauth_version"] = OAuth.version
        authorizationParameters["oauth_signature_method"] =  OAuth.signatureMethod
        authorizationParameters["oauth_consumer_key"] = credential.consumer_key
        authorizationParameters["oauth_timestamp"] = String(Int64(NSDate().timeIntervalSince1970))
        authorizationParameters["oauth_nonce"] = (NSUUID().UUIDString as NSString).substringToIndex(8)
        
        if (credential.oauth_token != ""){
            authorizationParameters["oauth_token"] = credential.oauth_token
        }
        
        for (key, value) in parameters {
            if key.hasPrefix("oauth_") {
                authorizationParameters.updateValue(value, forKey: key)
            }
        }
        
        let combinedParameters = authorizationParameters.join(parameters)
        
        let finalParameters = combinedParameters
        
        authorizationParameters["oauth_signature"] = self.signatureForMethod(method, url: url, parameters: finalParameters, credential: credential)
        
        var parameterComponents = authorizationParameters.urlEncodedQueryStringWithEncoding(dataEncoding).componentsSeparatedByString("&") as [String]
        parameterComponents.sortInPlace { $0 < $1 }
        
        var headerComponents = [String]()
        for component in parameterComponents {
            let subcomponent = component.componentsSeparatedByString("=") as [String]
            if subcomponent.count == 2 {
                headerComponents.append("\(subcomponent[0])=\"\(subcomponent[1])\"")
            }
        }
        
        return "OAuth " + headerComponents.joinWithSeparator(", ")
    }
    
    public class func signatureForMethod(method: String, url: NSURL, parameters: Dictionary<String, AnyObject>, credential: OAuthSwiftCredential) -> String {
        var tokenSecret: NSString = ""
        tokenSecret = credential.oauth_token_secret.urlEncodedStringWithEncoding(dataEncoding)
        
        let encodedConsumerSecret = credential.consumer_secret.urlEncodedStringWithEncoding(dataEncoding)
        
        let signingKey = "\(encodedConsumerSecret)&\(tokenSecret)"
        
        var parameterComponents = parameters.urlEncodedQueryStringWithEncoding(dataEncoding).componentsSeparatedByString("&") as [String]
        parameterComponents.sortInPlace { $0 < $1 }
        
        let parameterString = parameterComponents.joinWithSeparator("&")
        let encodedParameterString = parameterString.urlEncodedStringWithEncoding(dataEncoding)
        
        let encodedURL = url.absoluteString.urlEncodedStringWithEncoding(dataEncoding)
        
        let signatureBaseString = "\(method)&\(encodedURL)&\(encodedParameterString)"
        
        let key = signingKey.dataUsingEncoding(NSUTF8StringEncoding)!
        let msg = signatureBaseString.dataUsingEncoding(NSUTF8StringEncoding)!
        let sha1 = HMAC.sha1(key: key, message: msg)!
        return sha1.base64EncodedStringWithOptions([])
    }
}