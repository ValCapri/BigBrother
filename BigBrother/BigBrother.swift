//
//  BigBrother.swift
//  BigBrother
//
//  Created by Marcelo Fabri on 01/01/15.
//  Copyright (c) 2015 Marcelo Fabri. All rights reserved.
//

import Foundation
import UIKit

/**
Registers BigBrother to the shared NSURLSession (and to NSURLConnection).
*/
public func BigBrother_addToSharedSession() {
    NSURLProtocol.registerClass(BigBrotherURLProtocol.self)
}

/**
Adds BigBrother to a NSURLSessionConfiguration that will be used to create a custom NSURLSession.

:param: configuration The configuration on which BigBrother will be added
*/
public func BigBrother_addToSessionConfiguration(configuration: NSURLSessionConfiguration) {
    // needs to be inserted at the beginning (see https://github.com/AliSoftware/OHHTTPStubs/issues/65 )
    configuration.protocolClasses = [BigBrotherURLProtocol.self] + (configuration.protocolClasses ?? [])
}

/**
Removes BigBrother from the shared NSURLSession (and to NSURLConnection).
*/
public func BigBrother_removeFromSharedSession() {
    NSURLProtocol.unregisterClass(BigBrotherURLProtocol.self)
}

/**
Removes BigBrother from a NSURLSessionConfiguration.
You must create a new NSURLSession from the updated configuration to stop using BigBrother.

:param: configuration The configuration from which BigBrother will be removed (if present)
*/
public func BigBrother_removeFromSessionConfiguration(configuration: NSURLSessionConfiguration) {
    configuration.protocolClasses = configuration.protocolClasses?.filter {  $0 !== BigBrotherURLProtocol.self }
}

/**
*  A custom NSURLProtocol that automatically manages UIApplication.sharedApplication().networkActivityIndicatorVisible.
*/
public class BigBrotherURLProtocol : NSURLProtocol {
    
    var connection: NSURLConnection?
    var mutableData: NSMutableData?
    var response: NSURLResponse?
    
    struct BigBrotherSingleton {
        static var instance = BigBrotherManager.sharedInstance
    }
    
    /// The singleton instance.
    public class var manager: BigBrotherManager {
        get {
            return BigBrotherSingleton.instance
        }
        set {
            BigBrotherSingleton.instance = newValue
        }
    }
    
    // MARK: NSURLProtocol
    
    override public class func canInitWithRequest(request: NSURLRequest) -> Bool {
        if NSURLProtocol.propertyForKey(NSStringFromClass(self), inRequest: request) != nil {
            return false
        }
        
        return true
    }
    
    override public class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }
    
    override public class func requestIsCacheEquivalent(aRequest: NSURLRequest, toRequest bRequest: NSURLRequest) -> Bool {
        return super.requestIsCacheEquivalent(aRequest, toRequest:bRequest)
    }
    
    override public func startLoading() {
        BigBrotherURLProtocol.manager.incrementActivityCount()
        
        let newRequest = request.mutableCopy() as! NSMutableURLRequest
        NSURLProtocol.setProperty(true, forKey: NSStringFromClass(self.dynamicType), inRequest: newRequest)
        connection = NSURLConnection(request: newRequest, delegate: self)
    }
    
    override public func stopLoading() {
        connection?.cancel()
        connection = nil
        
        BigBrotherURLProtocol.manager.decrementActivityCount()
    }
    
    // MARK: NSURLConnectionDelegate
    
    func connection(connection: NSURLConnection!, didReceiveResponse response: NSURLResponse!) {
        let policy = NSURLCacheStoragePolicy(rawValue: request.cachePolicy.rawValue) ?? .NotAllowed
        client?.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: policy)
        
        self.response = response
        mutableData = NSMutableData()
    }
    
    func connection(connection: NSURLConnection!, didReceiveData data: NSData!) {
        client?.URLProtocol(self, didLoadData: data)
        mutableData?.appendData(data)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection!) {
        client?.URLProtocolDidFinishLoading(self)
    }
    
    func connection(connection: NSURLConnection!, didFailWithError error: NSError!) {
        client?.URLProtocol(self, didFailWithError: error)
    }
}
