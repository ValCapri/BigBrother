//
//  Manager.swift
//  BigBrother
//
//  Created by Marcelo Fabri on 01/01/15.
//  Copyright (c) 2015 Marcelo Fabri. All rights reserved.
//

import Foundation
import UIKit
import ObjectiveC

/**
*  A protocol that represents an object that can manage a network activity indicator.
*/
@objc
public protocol NetworkActivityIndicatorOwner {
    var bb_networkActivityIndicatorVisible: Bool { get set }
}

/**
*  UIApplication already conforms to NetworkActivityIndicatorOwner.
*/

extension UIApplication : NetworkActivityIndicatorOwner {
    public var bb_networkActivityIndicatorVisible: Bool {
        get {
            return self.networkActivityIndicatorVisible
        }
        set(newValue) {
            self.networkActivityIndicatorVisible = newValue
        }
    }
}

/**
   Manages manages the state of the network activity indicator in the status bar.
   Based on AFNetworkActivityIndicatorManager from AFNetworking.
*/
public class Manager {
    private var _activityCount: Int = 0
   
    private var activityCount: Int {
        get {
            return self._activityCount
        }
        set {
            synchronized(self, self._activityCount = newValue)
            dispatch_async(dispatch_get_main_queue()) {
                self.updateNetworkActivityIndicatorVisibility()
            }
        }
    }
    
    private var activityIndicatorVisibilityTimer: NSTimer?
    private let invisibilityDelay: NSTimeInterval = 0.17
    
    /// The responsible for owning the network activity indicator. Defaults to UIApplication.sharedApplication().
    public let application: NetworkActivityIndicatorOwner
    
    /// Indicates whether the network activity indicator is visible.
    public var networkActivityIndicatorVisible: Bool {
        return activityCount > 0
    }
    
    /**
        Inits a manager.
    
        :param: application The responsible for owning the network activity indicator. If omitted, defaults to UIApplication.sharedApplication().
    
        :returns: An initializated manager
    */
    public init(application: NetworkActivityIndicatorOwner = UIApplication.sharedApplication()){
        self.application = application
    }
    
    /// The singleton instance.
    public class var sharedInstance: Manager {
        struct Singleton {
            static let instance = Manager()
        }
        
        return Singleton.instance
    }
    
    /**
        Increments the number of active network requests. If this number was zero before incrementing, this will start animating the status bar network activity indicator.
    */
    public func incrementActivityCount() {
        synchronized(self, self._activityCount += 1)
        
        dispatch_async(dispatch_get_main_queue()) {
            self.updateNetworkActivityIndicatorVisibilityDelayed()
        }
    }
    
    /**
        Decrements the number of active network requests. If this number becomes zero after decrementing, this will stop animating the status bar network activity indicator.
    */
    public func decrementActivityCount() {
        synchronized(self, self._activityCount = max(self._activityCount - 1, 0))
        
        dispatch_async(dispatch_get_main_queue()) {
            self.updateNetworkActivityIndicatorVisibilityDelayed()
        }
    }
    
    // MARK: Private
    
    private func updateNetworkActivityIndicatorVisibility() {
        var visible = self.networkActivityIndicatorVisible
        self.application.bb_networkActivityIndicatorVisible = visible
    }
    
    private func updateNetworkActivityIndicatorVisibilityDelayed() {
        if !networkActivityIndicatorVisible {
            activityIndicatorVisibilityTimer?.invalidate()
            activityIndicatorVisibilityTimer = NSTimer(timeInterval: invisibilityDelay,
                target: self, selector: "updateNetworkActivityIndicatorVisibility", userInfo: nil, repeats: false)
            NSRunLoop.mainRunLoop().addTimer(activityIndicatorVisibilityTimer!, forMode: NSRunLoopCommonModes)
        } else {
            dispatch_async(dispatch_get_main_queue()) {
                self.updateNetworkActivityIndicatorVisibility()
            }
        }
    }
}

/**
    Runs a closure in a synchronized way.

    :param: lock    The object to be used to synchronize
    :param: closure The closure that will be run in a synchronized way
*/
private func synchronized(lock: AnyObject, @autoclosure closure:  () -> ()) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}