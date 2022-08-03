//
//  PropertyWapper.swift
//  Dayshee
//
//  Created by haiphan on 11/7/20.
//  Copyright © 2020 ThanhPham. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

// MARK: - Safe protocol
protocol SafeAccessProtocol {
    var lock: NSRecursiveLock { get }
}

extension SafeAccessProtocol {
    @discardableResult
    func excute<T>(block: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return block()
    }
}

// MARK: - Thread safe
@propertyWrapper
struct ThreadSafe<T>: SafeAccessProtocol {
    let lock: NSRecursiveLock = NSRecursiveLock()
    var _value: T?
    var wrappedValue: T? {
        get {
            return excute { _value }
        }
        
        set {
            excute { _value = newValue }
        }
    }
}

// MARK: - Replay
@propertyWrapper
struct Replay<T> {
    private let _event: ReplaySubject<T>
    private let queue: ImmediateSchedulerType
    init(bufferSize: Int, queue: ImmediateSchedulerType) {
        self.queue = queue
        _event = ReplaySubject<T>.create(bufferSize: bufferSize)
    }
    
    init(queue: ImmediateSchedulerType) {
        self.queue = queue
       _event = ReplaySubject<T>.create(bufferSize: 1)
    }
    
    var wrappedValue: T {
        get {
            fatalError("Do not get value from this!!!!")
        }
        
        set {
            _event.onNext(newValue)
        }
    }
    
    var projectedValue: Observable<T> {
        return _event.observeOn(queue)
    }
}

// MARK: - BehaviorReplay
@propertyWrapper
struct VariableReplay<T> {
    private let replay: BehaviorRelay<T>
    
    init(wrappedValue: T) {
        replay = BehaviorRelay(value: wrappedValue)
    }
    
    var wrappedValue: T {
        get {
            return replay.value
        }
        
        set {
            replay.accept(newValue)
        }
    }
    
    var projectedValue: BehaviorRelay<T> {
        return replay
    }
}

// MARK: - Published
@propertyWrapper
struct Published<T> {
    private let subject: PublishSubject<T> = PublishSubject()
    var wrappedValue: T {
        get {
            fatalError("Do not get value from this!!!!")
        }
        
        set {
            subject.onNext(newValue)
        }
    }
    
    var projectedValue: PublishSubject<T> {
        return subject
    }
}

// MARK: - Expired
@propertyWrapper
struct Exprired<T> {
    private let timeExpired: TimeInterval
    private var date: Date
    init(wrappedValue: T, timeExpired: TimeInterval) {
        self.wrappedValue = wrappedValue
        self.timeExpired = timeExpired
        date = Date().addingTimeInterval(timeExpired)
    }
    
    var wrappedValue: T {
        didSet {
            date = Date().addingTimeInterval(timeExpired)
        }
    }
    
    var projectedValue: T? {
        guard date.timeIntervalSince(Date()) > 0 else {
            return nil
        }
        
        return wrappedValue
    }
}

// MARK: - Trim
@propertyWrapper
struct Trimmed {
    private(set) var value: String = ""

    var wrappedValue: String {
        get { value }
        set { value = newValue.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    init(wrappedValue: String) {
        self.wrappedValue = wrappedValue
    }
}

// MARK: - UserDefault
@propertyWrapper
struct LoadUserDefault<T> {
    let key: String
    let defaultValue: T

    init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
            UserDefaults.standard.synchronize()
        }
    }
}

