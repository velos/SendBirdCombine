//
//  SBDQuery+Combine.swift
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

extension SBDGroupChannelListQuery {
    public func loadNextPage() -> AnyPublisher<[SBDGroupChannel], SBDError> {
        Future<[SBDGroupChannel], SBDError> { [weak self] promise in
            self?.loadNextPage { (channels, error) in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                
                guard let channels = channels else {
                    return promise(.success([]))
                }
                
                promise(.success(channels))
            }
        }
        .eraseToAnyPublisher()
    }
}

extension SBDGroupChannelMemberListQuery {
    public func loadNextPage() -> AnyPublisher<[SBDMember], SBDError> {
        Future<[SBDMember], SBDError> { [weak self] promise in
            self?.loadNextPage { (users, error) in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                
                guard let users = users else {
                    return promise(.success([]))
                }
                
                promise(.success(users))
            }
        }
        .eraseToAnyPublisher()
    }
}

extension SBDOpenChannelListQuery {
    public func loadNextPage() -> AnyPublisher<[SBDOpenChannel], SBDError> {
        Future<[SBDOpenChannel], SBDError> { [weak self] promise in
            self?.loadNextPage { (channels, error) in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                
                guard let channels = channels else {
                    return promise(.success([]))
                }
                
                promise(.success(channels))
            }
        }
        .eraseToAnyPublisher()
    }
}

extension SBDUserListQuery {
    public func loadNextPage() -> AnyPublisher<[SBDUser], SBDError> {
        Future<[SBDUser], SBDError> { [weak self] promise in
            self?.loadNextPage { (users, error) in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                
                guard let users = users else {
                    return promise(.success([]))
                }
                
                promise(.success(users))
            }
        }
        .eraseToAnyPublisher()
    }
}

extension SBDFriendListQuery {
    public func loadNextPage() -> AnyPublisher<[SBDUser], SBDError> {
        Future<[SBDUser], SBDError> { [weak self] promise in
            self?.loadNextPage { (users, error) in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                
                guard let users = users else {
                    return promise(.success([]))
                }
                
                promise(.success(users))
            }
        }
        .eraseToAnyPublisher()
    }
}

extension SBDMessageSearchQuery {
    public func loadNextPage() -> AnyPublisher<[SBDBaseMessage], SBDError> {
        Future<[SBDBaseMessage], SBDError> { [weak self] promise in
            self?.loadNextPage { (messages, error) in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                
                guard let messages = messages else {
                    return promise(.success([]))
                }
                
                promise(.success(messages))
            }
        }
        .eraseToAnyPublisher()
    }
}
