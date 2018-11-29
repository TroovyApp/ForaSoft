//
//  MulticastDelegate.swift
//  troovy-ios
//
//  Created by Daniil on 26.09.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation

class MulticastDelegate <T> {
    private var weakDelegates = [WeakWrapper]()
    
    func addDelegate(delegate: T) {
        for (index, delegateInArray) in self.weakDelegates.enumerated().reversed() {
            if delegateInArray.value === (delegate as AnyObject) {
                self.weakDelegates.remove(at: index)
            }
        }
        
        self.weakDelegates.append(WeakWrapper(value: delegate as AnyObject))
    }
    
    func removeDelegate(delegate: T) {
        for (index, delegateInArray) in self.weakDelegates.enumerated().reversed() {
            if delegateInArray.value === (delegate as AnyObject) {
                self.weakDelegates.remove(at: index)
            }
        }
    }
    
    func invoke(invocation: (T) -> ()) {
        for (index, delegate) in self.weakDelegates.enumerated().reversed() {
            if let delegate = delegate.value {
                invocation(delegate as! T)
            }
            else {
                self.weakDelegates.remove(at: index)
            }
        }
    }
}

func += <T: AnyObject> (left: MulticastDelegate<T>, right: T) {
    left.addDelegate(delegate: right)
}

func -= <T: AnyObject> (left: MulticastDelegate<T>, right: T) {
    left.removeDelegate(delegate: right)
}

private class WeakWrapper {
    weak var value: AnyObject?
    
    init(value: AnyObject) {
        self.value = value
    }
}

