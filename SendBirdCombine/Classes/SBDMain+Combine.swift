//
//  SendBirdCombine.swift
//  SendBirdCombine
//
//  Created by David Rajan on 4/9/20.
//

import Foundation
import Combine
import SendBirdSDK

public enum SendingStatus {
    case temp(SBDBaseMessage)
    case sent(SBDBaseMessage)
}

public enum SendingFailure: Error {
    case generalFailure(SBDError)
    case sendingFailed(SBDBaseMessage, SBDError)
}

extension SBDMain {
    public static func connect(userId: String) -> Future<SBDUser, SBDError> {
        Future<SBDUser, SBDError> { promise in
            SBDMain.connect(withUserId: userId) { (user, error) in
                guard let user = user, error == nil else {
                    return promise(.failure(error!))
                }
                promise(.success(user))
            }
        }
    }
    
    public static func disconnect() -> Future<Void, Never> {
        Future<Void, Never> { promise in
            SBDMain.disconnect() {
                return promise(.success(()))
            }
        }
    }
    
    public static func blockUser(_ user: SBDUser) -> Future<SBDUser, SBDError> {
        Future<SBDUser, SBDError> { promise in
            SBDMain.blockUser(user) { (user, error) in
                guard let user = user, error == nil else {
                    return promise(.failure(error!))
                }
                promise(.success(user))
            }
        }
    }
    
    public static func unblockUser(_ user: SBDUser) -> Future<Void, SBDError> {
        Future<Void, SBDError> { promise in
            SBDMain.unblockUser(user) { error in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                promise(.success(()))
            }
        }
    }
}

extension SBDGroupChannel {
    public static func createChannel(with params: SBDGroupChannelParams) -> Future<SBDGroupChannel, SBDError> {
        Future<SBDGroupChannel, SBDError> { promise in
            SBDGroupChannel.createChannel(with: params) { (channel, error) in
                guard let channel = channel, error == nil else {
                    return promise(.failure(error!))
                }
                promise(.success(channel))
            }
        }
    }
    
    public func sendUserMessage(_ message: String?) -> AnyPublisher<SendingStatus, SendingFailure> {
        let messageSubject = CurrentValueSubject<SendingStatus?, SendingFailure>(nil)

        let tempMessage = sendUserMessage(message) { (message, error) in
            guard let sentMessage = message else {
                messageSubject.send(completion: .failure(SendingFailure.generalFailure(error!)))
                return
            }
            
            guard error == nil else {
                messageSubject.send(completion: .failure(SendingFailure.sendingFailed(sentMessage, error!)))
                return
            }
            
            messageSubject.send(SendingStatus.sent(sentMessage))
            messageSubject.send(completion: .finished)
        }
        
        messageSubject.value = SendingStatus.temp(tempMessage)
        
        return messageSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    public func sendFileMessage(_ data: Data, filename: String = UUID().uuidString, type: String) -> AnyPublisher<SendingStatus, SendingFailure> {
        let messageSubject = CurrentValueSubject<SendingStatus?, SendingFailure>(nil)

        let tempMessage = sendFileMessage(withBinaryData: data, filename: filename, type: type, size: UInt(data.count), data: nil) { (message, error) in
            guard let sentMessage = message else {
                messageSubject.send(completion: .failure(SendingFailure.generalFailure(error!)))
                return
            }
            
            guard error == nil else {
                messageSubject.send(completion: .failure(SendingFailure.sendingFailed(sentMessage, error!)))
                return
            }
            
            messageSubject.send(SendingStatus.sent(sentMessage))
            messageSubject.send(completion: .finished)
        }
        
        messageSubject.value = SendingStatus.temp(tempMessage)
        
        return messageSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    public func resendTextMessage(_ message: SBDUserMessage) -> AnyPublisher<SendingStatus, SendingFailure> {
        Future<SendingStatus, SendingFailure> { [weak self] promise in
            self?.resendUserMessage(with: message) { (message, error) in
                guard let sentMessage = message else {
                    return promise(.failure(SendingFailure.generalFailure(error!)))
                }
                
                guard error == nil else {
                    return promise(.failure(SendingFailure.sendingFailed(sentMessage, error!)))
                }
                
                promise(.success(SendingStatus.sent(sentMessage)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func resendFileMessage(_ message: SBDFileMessage, data: Data?) -> AnyPublisher<SendingStatus, SendingFailure> {
        Future<SendingStatus, SendingFailure> { [weak self] promise in
            self?.resendFileMessage(with: message, binaryData: data) { (message, error) in
                guard let sentMessage = message else {
                    return promise(.failure(SendingFailure.generalFailure(error!)))
                }
                
                guard error == nil else {
                    return promise(.failure(SendingFailure.sendingFailed(sentMessage, error!)))
                }
                
                promise(.success(SendingStatus.sent(sentMessage)))
            }
        }
        .eraseToAnyPublisher()
    }
}

extension SBDGroupChannelListQuery {
    public func loadNextPage() -> Future<[SBDGroupChannel], SBDError> {
        Future<[SBDGroupChannel], SBDError> { promise in
            self.loadNextPage { (channels, error) in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                
                guard let channels = channels else {
                    return promise(.success([]))
                }
                
                promise(.success(channels))
            }
        }
    }
}

extension SBDApplicationUserListQuery {
    public func loadNextPage() -> Future<[SBDUser], SBDError> {
        Future<[SBDUser], SBDError> { promise in
            self.loadNextPage { (users, error) in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                
                guard let users = users else {
                    return promise(.success([]))
                }
                
                promise(.success(users))
            }
        }
    }
}
