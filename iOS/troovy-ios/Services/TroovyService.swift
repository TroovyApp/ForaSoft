//
//  TroovyService.swift
//  troovy-ios
//
//  Created by Daniil on 11.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation

enum ServiceActionResult: Error {
    case methodStarted(method: String)
    case methodSucceeded(method: String)
    case methodSucceededWithResponseDictionary(method: String, resultDictionary: [String:Any])
    case methodSucceededWithResponseArray(method: String, resultArray: [[String:Any]])
    case methodSucceededWithObject(method: String, object: AnyObject?)
    case methodSucceededWithMessage(method: String, resultString: String)
    case methodProgressedWithProgress(method: String, progress: Double)
    case methodFailed(method: String, error: String?)
    case methodCancelled(method: String)
}

protocol TroovyServiceDelegate: class {
    func serviceStateChanged(withActionResult result: ServiceActionResult)
}

class TroovyService {
    
    // MARK: Public Properties
    
    /// Delegate. Responds to TroovyServiceDelegate and processes ServiceActionResult.
    weak var delegate: TroovyServiceDelegate? {
        didSet {
            self.saveDelegate(self.delegate)
        }
    }
    
    // MARK: Private Properties
    
    private var delegates = MulticastDelegate<TroovyServiceDelegate>()
    
    // MARK: Public Methods
    
    /// Calls block on the main thread if needed.
    ///
    /// - parameters block: Block to be called.
    ///
    func performOnMainThread(block: (() -> ())?) {
        guard let blockToPerform = block else {
            return
        }
        
        if Thread.isMainThread {
            blockToPerform()
        } else {
            DispatchQueue.main.async {
                blockToPerform()
            }
        }
    }
    
    // MARK: Internal Methods
    
    /// Calls delegate serviceStateChanged(withActionResult:) on the main thread if needed.
    ///
    /// - parameter serviceResult: New service action result.
    ///
    internal func serviceResultChanged(withResult result: ServiceActionResult) {
        if Thread.isMainThread {
            self.delegates.invoke(invocation: { (serviceDelegate) in
                serviceDelegate.serviceStateChanged(withActionResult: result)
            })
        } else {
            DispatchQueue.main.async {
                self.delegates.invoke(invocation: { (serviceDelegate) in
                    serviceDelegate.serviceStateChanged(withActionResult: result)
                })
            }
        }
    }
    
    // MARK: Private Methods
    
    private func saveDelegate(_ delegate: TroovyServiceDelegate?) {
        guard let object = delegate else {
            return
        }
        
        self.delegates.addDelegate(delegate: object)
    }
    
}
