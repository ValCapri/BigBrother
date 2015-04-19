//
//  BigBrotherTests.swift
//  BigBrother
//
//  Created by Marcelo Fabri on 02/01/15.
//  Copyright (c) 2015 Marcelo Fabri. All rights reserved.
//

import UIKit
import XCTest
import BigBrother

class BigBrotherTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        BigBrother.BigBrotherURLProtocol.manager = BigBrother.BigBrotherManager(application: UIApplication.sharedApplication())
    }
    
    override func tearDown() {
        BigBrother.BigBrotherURLProtocol.manager = BigBrother.BigBrotherManager()
        
        super.tearDown()
    }
    
    func testThatNetworkActivityIndicationTurnsOffWithURL(URL: NSURL) {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        BigBrother.BigBrother_addToSessionConfiguration(configuration)
        
        let session = NSURLSession(configuration: configuration)
        
        let expectation = expectationWithDescription("GET \(URL)")
        
        let task = session.dataTaskWithURL(URL) { (data, response, error) in
            delay(0.2) {
                expectation.fulfill()
                XCTAssertFalse(UIApplication.sharedApplication().networkActivityIndicatorVisible)
            }
        }
        
        task.resume()
        
        let invisibilityDelayExpectation = expectationWithDescription("TurnOnInvisibilityDelayExpectation")
        delay(0.2) {
            invisibilityDelayExpectation.fulfill()
            XCTAssertFalse(UIApplication.sharedApplication().networkActivityIndicatorVisible)
        }
        
        waitForExpectationsWithTimeout(task.originalRequest.timeoutInterval + 1) { (error) in
            task.cancel()
        }
    }

    func testThatNetworkActivityIndicatorTurnsOffIndicatorWhenRequestSucceeds() {
        let URL =  NSURL(string: "http://httpbin.org/get")!
        testThatNetworkActivityIndicationTurnsOffWithURL(URL)
    }
    
    func testThatNetworkActivityIndicatorTurnsOffIndicatorWhenRequestFails() {
        let URL =  NSURL(string: "http://httpbin.org/status/500")!
        testThatNetworkActivityIndicationTurnsOffWithURL(URL)
    }
}

private func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}
