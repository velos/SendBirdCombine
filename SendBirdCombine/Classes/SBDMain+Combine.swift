//
//  SBDMain+Combine.swift
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
import SendBirdSDK

extension SBDMain {
    public var userPublisher: AnyPublisher<UserEvent, Never> {
        return SendbirdDelegateProxy.sharedInstance.userPassthrough.eraseToAnyPublisher()
    }
    
    public var connectionPublisher: AnyPublisher<ConnectionEvent, Never> {
        return SendbirdDelegateProxy.sharedInstance.connectionPassthrough.eraseToAnyPublisher()
    }

    public static func connect(userId: String, accessToken: String? = nil, apiHost: String? = nil, wsHost: String? = nil) -> AnyPublisher<SBDUser, SBDError> {
        Future<SBDUser, SBDError> { promise in
            connect(withUserId: userId, accessToken: accessToken, apiHost: apiHost, wsHost: wsHost) { (user, error) in
                guard let user = user, error == nil else {
                    return promise(.failure(error!))
                }
                promise(.success(user))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public static func disconnect() -> AnyPublisher<Void, Never> {
        Future<Void, Never> { promise in
            disconnect() {
                return promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public static func blockUserId(_ userId: String) -> AnyPublisher<SBDUser, SBDError> {
        Future<SBDUser, SBDError> { promise in
            blockUserId(userId) { (user, error) in
                guard let blockedUser = user, error == nil else {
                    return promise(.failure(error!))
                }
                promise(.success(blockedUser))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public static func blockUser(_ user: SBDUser) -> AnyPublisher<SBDUser, SBDError> {
        Future<SBDUser, SBDError> { promise in
            blockUser(user) { (user, error) in
                guard let user = user, error == nil else {
                    return promise(.failure(error!))
                }
                promise(.success(user))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public static func unblockUserId(_ userId: String) -> AnyPublisher<Void, SBDError> {
        Future<Void, SBDError> { promise in
            unblockUserId(userId) { error in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public static func unblockUser(_ user: SBDUser) -> AnyPublisher<Void, SBDError> {
        Future<Void, SBDError> { promise in
            unblockUser(user) { error in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public static func updateCurrentUserInfo(withNickname nickname: String?, profileUrl: String?) -> AnyPublisher<Void, SBDError> {
        Future<Void, SBDError> { promise in
            updateCurrentUserInfo(withNickname: nickname, profileUrl: profileUrl) { error in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public static func updateCurrentUserInfo(withNickname nickname: String?, profileImage: Data?) -> AnyPublisher<Void, SBDError> {
        Future<Void, SBDError> { promise in
            updateCurrentUserInfo(withNickname: nickname, profileImage: profileImage) { error in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public static func registerDevicePushKitToken(_ token: Data, unique: Bool) -> AnyPublisher<SBDPushTokenRegistrationStatus, SBDError> {
        Future<SBDPushTokenRegistrationStatus, SBDError> { promise in
            registerDevicePushKitToken(token, unique: unique) { (status, error) in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                promise(.success(status))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public static func unregisterDevicePushKitToken(_ token: Data) -> AnyPublisher<[AnyHashable : Any], SBDError> {
        Future<[AnyHashable : Any], SBDError> { promise in
            unregisterPushKitToken(token) { (response, error) in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                promise(.success(response ?? [:]))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public static func unregisterAllDevicePushKitToken() -> AnyPublisher<[AnyHashable : Any], SBDError> {
        Future<[AnyHashable : Any], SBDError> { promise in
            unregisterAllPushKitToken() { (response, error) in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                promise(.success(response ?? [:]))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public static func getChannelCount(with filter: SBDMemberStateFilter) -> AnyPublisher<UInt, SBDError> {
        Future<UInt, SBDError> { promise in
            getChannelCount(with: filter) { (count, error) in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                promise(.success(count))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public static func getTotalUnreadChannelCount() -> AnyPublisher<UInt, SBDError> {
        Future<UInt, SBDError> { promise in
            getTotalUnreadChannelCount() { (count, error) in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                promise(.success(count))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public static func getTotalUnreadMessageCount(with params: SBDGroupChannelTotalUnreadMessageCountParams? = nil) -> AnyPublisher<UInt, SBDError> {
        Future<UInt, SBDError> { promise in
            guard let params = params else {
                getTotalUnreadMessageCount { (count, error) in
                    guard error == nil else {
                        return promise(.failure(error!))
                    }
                    promise(.success(count))
                }
                return
            }
            
            getTotalUnreadMessageCount(with: params) { (count, error) in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                promise(.success(count))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public static func getUnreadItemCount(with key: SBDUnreadItemKey) -> AnyPublisher<SBDUnreadItemCount, SBDError> {
        Future<SBDUnreadItemCount, SBDError> { promise in
            getUnreadItemCount(with: key) { (count, error) in
                guard let count = count, error == nil else {
                    return promise(.failure(error!))
                }
                promise(.success(count))
            }
        }
        .eraseToAnyPublisher()
    }
}
