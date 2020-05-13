//
//  SendBirdCalls+Combine.swift
//  SendBirdCombine
//
//  The MIT License (MIT)
//
//  Copyright (c) 2020 Velos Mobile LLC.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import Combine
import PushKit
import SendBirdSDK
import SendBirdCalls
import CallKit

typealias VoidCallsResult = Result<Void, SBCError>

public enum SendBirdCallsEvent {
    case customItemsUpdated([String: String], [String])
    case customItemsDeleted([String: String], [String])
}

extension SendBirdCall {
    public static var eventPublisher: AnyPublisher<SendBirdCallEvent, Never> {
        return SendBirdCallsDelegateProxy.sharedInstance.callPassthrough.eraseToAnyPublisher()
    }

    public static func authenticate(with params: AuthenticateParams) -> AnyPublisher<User, SBCError> {
        Future<User, SBCError> { promise in
            authenticate(with: params, completionHandler: Result.handle(promise: promise))
        }
        .eraseToAnyPublisher()
    }

    public static func deauthenticate(voipPushToken: Data?) -> AnyPublisher<Void, SBCError> {
        Future<Void, SBCError> { promise in
            deauthenticate(voipPushToken: voipPushToken, completionHandler: VoidCallsResult.handle(promise: promise))
        }
        .eraseToAnyPublisher()
    }

    public static func dial(with params: DialParams) -> AnyPublisher<DirectCall, SBCError> {
        Future<DirectCall, SBCError> { promise in
            dial(with: params, completionHandler: Result.handle(promise: promise))
        }
        .eraseToAnyPublisher()
    }

    public static func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) -> AnyPublisher<UUID, Never> {
        Future<UUID?, Never> { promise in
            pushRegistry(registry, didReceiveIncomingPushWith: payload, for: type) { uuid in
                promise(.success(uuid))
            }
        }
        .compactMap { $0 }
        .eraseToAnyPublisher()
    }

    public static func registerVoIPPush(token: Data?, unique: Bool = false) -> AnyPublisher<Void, SBCError> {
        Future<Void, SBCError> { promise in
            registerVoIPPush(token: token, unique: unique, completionHandler: VoidCallsResult.handle(promise: promise))
        }
        .eraseToAnyPublisher()
    }

    public static func unregisterVoIPPush(token: Data?) -> AnyPublisher<Void, SBCError> {
        Future<Void, SBCError> { promise in
            unregisterVoIPPush(token: token, completionHandler: VoidCallsResult.handle(promise: promise))
        }
        .eraseToAnyPublisher()
    }

    public static func unregisterAllVoIPPushTokens() -> AnyPublisher<Void, SBCError> {
        Future<Void, SBCError> { promise in
            unregisterAllVoIPPushTokens(completionHandler: VoidCallsResult.handle(promise: promise))
        }
        .eraseToAnyPublisher()
    }

    public static func registerRemotePush(token: Data?, unique: Bool = false) -> AnyPublisher<Void, SBCError> {
        Future<Void, SBCError> { promise in
            registerRemotePush(token: token, unique: unique, completionHandler: VoidCallsResult.handle(promise: promise))
        }
        .eraseToAnyPublisher()
    }

    public static func unregisterRemotePush(token: Data?) -> AnyPublisher<Void, SBCError> {
        Future<Void, SBCError> { promise in
            unregisterRemotePush(token: token, completionHandler: VoidCallsResult.handle(promise: promise))
        }
        .eraseToAnyPublisher()
    }

    public static func unregisterAllRemotePushTokens() -> AnyPublisher<Void, SBCError> {
        Future<Void, SBCError> { promise in
            unregisterAllRemotePushTokens(completionHandler: VoidCallsResult.handle(promise: promise))
        }
        .eraseToAnyPublisher()
    }

}

extension DirectCall {
    public var eventPublisher: AnyPublisher<DirectCallEvent, Never> {
        self.delegate = SendBirdCallsDelegateProxy.sharedInstance

        return SendBirdCallsDelegateProxy.sharedInstance.directCallPassthrough
            .filter { $0.call == self }
            .map { $0.event }
            .eraseToAnyPublisher()
    }

    public func updateCustomItems(customItems: [String: String]) -> AnyPublisher<SendBirdCallsEvent, SBCError> {
        Future<SendBirdCallsEvent, SBCError> { [weak self] promise in
            self?.updateCustomItems(customItems: customItems, completionHandler: { (modifiedCustomItems, modifiedCustomItemsKeys, error) in
                guard error == nil else {
                    if let error = error {
                        return promise(.failure(error))
                    } else {
                        fatalError("Error must not be nil")
                    }
                }

                promise(.success(.customItemsUpdated(modifiedCustomItems ?? [:], modifiedCustomItemsKeys ?? [])))
            })
        }
        .eraseToAnyPublisher()

    }

    public func deleteCustomItems(customItemKeys: [String]) -> AnyPublisher<SendBirdCallsEvent, SBCError> {
        Future<SendBirdCallsEvent, SBCError> { [weak self] promise in
            self?.deleteCustomItems(customItemKeys: customItemKeys, completionHandler: { (modifiedCustomItems, modifiedCustomItemsKeys, error) in
                guard error == nil else {
                    if let error = error {
                        return promise(.failure(error))
                    } else {
                        fatalError("Error must not be nil")
                    }
                }

                promise(.success(.customItemsDeleted(modifiedCustomItems ?? [:], modifiedCustomItemsKeys ?? [])))
            })
        }
        .eraseToAnyPublisher()

    }

    public func deleteAllCustomItems() -> AnyPublisher<SendBirdCallsEvent, SBCError> {
        Future<SendBirdCallsEvent, SBCError> { [weak self] promise in
            self?.deleteAllCustomItems { (modifiedCustomItems, modifiedCustomItemsKeys, error) in
                guard error == nil else {
                    if let error = error {
                        return promise(.failure(error))
                    } else {
                        fatalError("Error must not be nil")
                    }
                }

                promise(.success(.customItemsDeleted(modifiedCustomItems ?? [:], modifiedCustomItemsKeys ?? [])))
            }
        }
        .eraseToAnyPublisher()
    }

    public func selectVideoDevice(device: VideoDevice) -> AnyPublisher<Void, SBCError> {
        Future<Void, SBCError> { [weak self] promise in
            self?.selectVideoDevice(device, completionHandler: VoidCallsResult.handle(promise: promise))
        }
        .eraseToAnyPublisher()
    }

    public func switchCamera() -> AnyPublisher<Void, SBCError> {
        Future<Void, SBCError> { [weak self] promise in
            self?.switchCamera(completionHandler: VoidCallsResult.handle(promise: promise))
        }
        .eraseToAnyPublisher()
    }
}

extension DirectCallLogListQuery {
    public func next() -> AnyPublisher<[DirectCallLog], SBCError> {
        Future<[DirectCallLog], SBCError> { [weak self] promise in
            self?.next(completionHandler: Result.handle(promise: promise))
        }
        .eraseToAnyPublisher()
    }
}
