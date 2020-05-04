//
//  SBDBaseChannel+Combine.swift
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

public enum ChannelCreateEvent {
    case created(SBDBaseChannel)
    case createdDistinct(SBDBaseChannel, Bool)
    case progress(Int64, Int64, Int64)
}

public enum MessageEvent {
    case tempMessage(SBDBaseMessage)
    case sentMessage(SBDBaseMessage)
    case progress(Int64, Int64, Int64)
}

public enum MessageFailure: Error {
    case generalFailure(SBDError)
    case sendingFailed(SBDBaseMessage, SBDError)
}

extension SBDBaseChannel {
    public var eventPublisher: AnyPublisher<ChannelEvent, Never> {
        return SendbirdDelegateProxy.sharedInstance.channelPassthrough
            .filter { $0.channel == self }
            .map { $0.event }
            .eraseToAnyPublisher()
    }

    public func sendUserMessage(_ message: String?) -> AnyPublisher<MessageEvent, MessageFailure> {
        let messageSubject = CurrentValueSubject<MessageEvent?, MessageFailure>(nil)

        let tempMessage = sendUserMessage(message) { (message, error) in
            guard let sentMessage = message else {
                messageSubject.send(completion: .failure(MessageFailure.generalFailure(error!)))
                return
            }
            
            guard error == nil else {
                messageSubject.send(completion: .failure(MessageFailure.sendingFailed(sentMessage, error!)))
                return
            }
            
            messageSubject.send(MessageEvent.sentMessage(sentMessage))
            messageSubject.send(completion: .finished)
        }
        
        messageSubject.value = MessageEvent.tempMessage(tempMessage)
        
        return messageSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    public func sendFileMessage(withUrl url: String, filename: String? = nil, size: UInt, type: String, data: String? = nil, customType: String? = nil) -> AnyPublisher<MessageEvent, MessageFailure> {
        
        let messageSubject = CurrentValueSubject<MessageEvent?, MessageFailure>(nil)
        
        let tempMessage = sendFileMessage(withUrl: url, filename: filename, size: size, type: type, data: data, customType: customType) { (message, error) in
            guard let sentMessage = message else {
                messageSubject.send(completion: .failure(MessageFailure.generalFailure(error!)))
                return
            }
            
            guard error == nil else {
                messageSubject.send(completion: .failure(MessageFailure.sendingFailed(sentMessage, error!)))
                return
            }
            
            messageSubject.send(MessageEvent.sentMessage(sentMessage))
            messageSubject.send(completion: .finished)
        }
        
        messageSubject.value = MessageEvent.tempMessage(tempMessage)
        
        return messageSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    public func sendFileMessage(withParams params: SBDFileMessageParams) -> AnyPublisher<MessageEvent, MessageFailure> {
        let messageSubject = CurrentValueSubject<MessageEvent?, MessageFailure>(nil)
        
        let tempMessage = sendFileMessage(with: params, progressHandler: { (bytesSent, totalBytesSent, totalExpectedBytesToSend) in
            messageSubject.send(.progress(bytesSent, totalBytesSent, totalExpectedBytesToSend))
        }) { (message, error) in
            guard let sentMessage = message else {
                messageSubject.send(completion: .failure(MessageFailure.generalFailure(error!)))
                return
            }
            
            guard error == nil else {
                messageSubject.send(completion: .failure(MessageFailure.sendingFailed(sentMessage, error!)))
                return
            }
            
            messageSubject.send(MessageEvent.sentMessage(sentMessage))
            messageSubject.send(completion: .finished)
        }
        
        messageSubject.value = MessageEvent.tempMessage(tempMessage)
        
        return messageSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    public func sendFileMessage(withBinaryData binaryData: Data, filename: String = UUID().uuidString, type: String, thumbnailSizes: [SBDThumbnailSize]? = nil, data: String? = nil, customType: String? = nil) -> AnyPublisher<MessageEvent, MessageFailure> {
        let messageSubject = CurrentValueSubject<MessageEvent?, MessageFailure>(nil)

        let tempMessage = sendFileMessage(withBinaryData: binaryData, filename: filename, type: type, size: UInt(binaryData.count), thumbnailSizes: thumbnailSizes, data: data, customType: customType, progressHandler: { (bytesSent, totalBytesSent, totalExpectedBytesToSend) in
            messageSubject.send(.progress(bytesSent, totalBytesSent, totalExpectedBytesToSend))
        }) { (message, error) in
            guard let sentMessage = message else {
                messageSubject.send(completion: .failure(MessageFailure.generalFailure(error!)))
                return
            }
            
            guard error == nil else {
                messageSubject.send(completion: .failure(MessageFailure.sendingFailed(sentMessage, error!)))
                return
            }
            
            messageSubject.send(MessageEvent.sentMessage(sentMessage))
            messageSubject.send(completion: .finished)
        }

        messageSubject.value = MessageEvent.tempMessage(tempMessage)
        
        return messageSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    public func deleteMessage(_ message: SBDUserMessage) -> AnyPublisher<Void, SBDError> {
        Future<Void, SBDError> { [weak self] promise in
            self?.delete(message) { error in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func updateUserMessage(_ message: SBDUserMessage, text: String?, data: String? = nil, customType: String? = nil) -> AnyPublisher<MessageEvent, MessageFailure> {
        Future<MessageEvent, MessageFailure> { [weak self] promise in
            self?.update(message, messageText: text, data: data, customType: customType, completionHandler: { (message, error) in
                guard let sentMessage = message else {
                    return promise(.failure(MessageFailure.generalFailure(error!)))
                }
                
                guard error == nil else {
                    return promise(.failure(MessageFailure.sendingFailed(sentMessage, error!)))
                }
                
                promise(.success(MessageEvent.sentMessage(sentMessage)))
            })
        }
        .eraseToAnyPublisher()
    }
    
    public func updateUserMessage(withId messageId: Int64, params: SBDUserMessageParams) -> AnyPublisher<MessageEvent, MessageFailure> {
        Future<MessageEvent, MessageFailure> { [weak self] promise in
            self?.updateUserMessage(withMessageId: messageId, userMessageParams: params, completionHandler: { (message, error) in
                guard let sentMessage = message else {
                    return promise(.failure(MessageFailure.generalFailure(error!)))
                }
                
                guard error == nil else {
                    return promise(.failure(MessageFailure.sendingFailed(sentMessage, error!)))
                }
                
                promise(.success(MessageEvent.sentMessage(sentMessage)))
            })
        }
        .eraseToAnyPublisher()
    }
    
    public func updateFileMessage(_ message: SBDFileMessage, data: String? = nil, customType: String? = nil) -> AnyPublisher<MessageEvent, MessageFailure> {
        Future<MessageEvent, MessageFailure> { [weak self] promise in
            self?.update(message, data: data, customType: customType, completionHandler: { (message, error) in
                guard let sentMessage = message else {
                    return promise(.failure(MessageFailure.generalFailure(error!)))
                }
                
                guard error == nil else {
                    return promise(.failure(MessageFailure.sendingFailed(sentMessage, error!)))
                }
                
                promise(.success(MessageEvent.sentMessage(sentMessage)))
            })
        }
        .eraseToAnyPublisher()
    }
    
    public func updateFileMessage(withId messageId: Int64, params: SBDFileMessageParams) -> AnyPublisher<MessageEvent, MessageFailure> {
        Future<MessageEvent, MessageFailure> { [weak self] promise in
            self?.updateFileMessage(withMessageId: messageId, fileMessageParams: params, completionHandler: { (message, error) in
                guard let sentMessage = message else {
                    return promise(.failure(MessageFailure.generalFailure(error!)))
                }
                
                guard error == nil else {
                    return promise(.failure(MessageFailure.sendingFailed(sentMessage, error!)))
                }
                
                promise(.success(MessageEvent.sentMessage(sentMessage)))
            })
        }
        .eraseToAnyPublisher()
    }
    
    public func resendTextMessage(_ message: SBDUserMessage) -> AnyPublisher<MessageEvent, MessageFailure> {
        let messageSubject = CurrentValueSubject<MessageEvent?, MessageFailure>(nil)

        let tempMessage = resendUserMessage(with: message) { (message, error) in
            guard let sentMessage = message else {
                messageSubject.send(completion: .failure(MessageFailure.generalFailure(error!)))
                return
            }
            
            guard error == nil else {
                messageSubject.send(completion: .failure(MessageFailure.sendingFailed(sentMessage, error!)))
                return
            }
            
            messageSubject.send(MessageEvent.sentMessage(sentMessage))
            messageSubject.send(completion: .finished)
        }
        
        messageSubject.value = MessageEvent.tempMessage(tempMessage)
        
        return messageSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    public func resendFileMessage(_ message: SBDFileMessage, data: Data?) -> AnyPublisher<MessageEvent, MessageFailure> {
        let messageSubject = CurrentValueSubject<MessageEvent?, MessageFailure>(nil)
        
        let tempMessage = resendFileMessage(with: message, binaryData: data, progressHandler: { (bytesSent, totalBytesSent, totalExpectedBytesToSend) in
            messageSubject.send(.progress(bytesSent, totalBytesSent, totalExpectedBytesToSend))
        }) { (message, error) in
            guard let sentMessage = message else {
                messageSubject.send(completion: .failure(MessageFailure.generalFailure(error!)))
                return
            }
            
            guard error == nil else {
                messageSubject.send(completion: .failure(MessageFailure.sendingFailed(sentMessage, error!)))
                return
            }
            
            messageSubject.send(MessageEvent.sentMessage(sentMessage))
            messageSubject.send(completion: .finished)
        }
        
        messageSubject.value = MessageEvent.tempMessage(tempMessage)
        
        return messageSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    public func getNextMessages(byTimestamp timestamp: Int64, inclusiveTimestamp: Bool = true, limit: Int = Int.max, reverse: Bool = false, messageType: SBDMessageTypeFilter = .all, customType: String? = nil, senderUserIds: [String]? = nil, includeMetaArray: Bool = true, includeReactions: Bool = true) -> AnyPublisher<[SBDBaseMessage], SBDError> {

        Future<[SBDBaseMessage], SBDError> { [weak self] promise in
            self?.getNextMessages(byTimestamp: timestamp, inclusiveTimestamp: inclusiveTimestamp, limit: limit, reverse: reverse, messageType: messageType, customType: customType, senderUserIds: senderUserIds, includeMetaArray: includeMetaArray, includeReactions: includeReactions) { (messages, error) in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                
                promise(.success(messages ?? []))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func getNextMessages(byId messageId: Int64, inclusiveTimestamp: Bool = true, limit: Int = Int.max, reverse: Bool = false, messageType: SBDMessageTypeFilter = .all, customType: String? = nil, senderUserIds: [String]? = nil, includeMetaArray: Bool = true, includeReactions: Bool = true) -> AnyPublisher<[SBDBaseMessage], SBDError> {
        Future<[SBDBaseMessage], SBDError> { [weak self] promise in
            self?.getNextMessages(byMessageId: messageId, inclusiveTimestamp: inclusiveTimestamp, limit: limit, reverse: reverse, messageType: messageType, customType: customType, senderUserIds: senderUserIds, includeMetaArray: includeMetaArray, includeReactions: includeReactions, completionHandler: { (messages, error) in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                
                promise(.success(messages ?? []))
            })
        }
        .eraseToAnyPublisher()
    }
    
    public func getPreviousMessages(byTimestamp timestamp: Int64, inclusiveTimestamp: Bool = true, limit: Int = Int.max, reverse: Bool = false, messageType: SBDMessageTypeFilter = .all, customType: String? = nil, senderUserIds: [String]? = nil, includeMetaArray: Bool = true, includeReactions: Bool = true) -> AnyPublisher<[SBDBaseMessage], SBDError> {

        Future<[SBDBaseMessage], SBDError> { [weak self] promise in
            self?.getPreviousMessages(byTimestamp: timestamp, inclusiveTimestamp: inclusiveTimestamp, limit: limit, reverse: reverse, messageType: messageType, customType: customType, senderUserIds: senderUserIds, includeMetaArray: includeMetaArray, includeReactions: includeReactions) { (messages, error) in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                
                promise(.success(messages ?? []))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func getPreviousMessages(byId messageId: Int64, inclusiveTimestamp: Bool = true, limit: Int = Int.max, reverse: Bool = false, messageType: SBDMessageTypeFilter = .all, customType: String? = nil, senderUserIds: [String]? = nil, includeMetaArray: Bool = true, includeReactions: Bool = true) -> AnyPublisher<[SBDBaseMessage], SBDError> {
        Future<[SBDBaseMessage], SBDError> { [weak self] promise in
            self?.getPreviousMessages(byMessageId: messageId, inclusiveTimestamp: inclusiveTimestamp, limit: limit, reverse: reverse, messageType: messageType, customType: customType, senderUserIds: senderUserIds, includeMetaArray: includeMetaArray, includeReactions: includeReactions, completionHandler: { (messages, error) in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                
                promise(.success(messages ?? []))
            })
        }
        .eraseToAnyPublisher()
    }
    
    public func getPreviousAndNextMessages(byTimestamp timestamp: Int64, inclusiveTimestamp: Bool = true, prevLimit: Int = Int.max, nextLimit: Int = Int.max, reverse: Bool = false, messageType: SBDMessageTypeFilter = .all, customType: String? = nil, senderUserIds: [String]? = nil, includeMetaArray: Bool = true, includeReactions: Bool = true) -> AnyPublisher<[SBDBaseMessage], SBDError> {
        Future<[SBDBaseMessage], SBDError> { [weak self] promise in
            self?.getPreviousAndNextMessages(byTimestamp: timestamp, prevLimit: prevLimit, nextLimit: nextLimit, reverse: reverse, messageType: messageType, customType: customType, senderUserIds: senderUserIds, includeMetaArray: includeMetaArray, includeReactions: includeReactions) { (messages, error) in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                
                promise(.success(messages ?? []))
            }
        }
        .eraseToAnyPublisher()
    }
}

extension SBDGroupChannel {
    public static func createChannel(with params: SBDGroupChannelParams) -> AnyPublisher<ChannelCreateEvent, SBDError> {
        Future<ChannelCreateEvent, SBDError> { promise in
            createChannel(with: params) { (channel, error) in
                guard let channel = channel, error == nil else {
                    return promise(.failure(error!))
                }
                promise(.success(.created(channel)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public static func createChannel(with users: [SBDUser], isDistinct: Bool = true) -> AnyPublisher<ChannelCreateEvent, SBDError> {
        Future<ChannelCreateEvent, SBDError> { promise in
            createChannel(with: users, isDistinct: isDistinct) { (channel, error) in
                guard let channel = channel, error == nil else {
                    return promise(.failure(error!))
                }
                promise(.success(.created(channel)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public static func createChannel(with userIds: [String], isDistinct: Bool = true) -> AnyPublisher<ChannelCreateEvent, SBDError> {
        Future<ChannelCreateEvent, SBDError> { promise in
            createChannel(withUserIds: userIds, isDistinct: isDistinct) { (channel, error) in
                guard let channel = channel, error == nil else {
                    return promise(.failure(error!))
                }
                promise(.success(.created(channel)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public static func createChannel(with name: String? = nil, isDistinct: Bool = true, userIds: [String], coverImage: Data, coverImageName: String, data: String? = nil, customType: String? = nil) -> AnyPublisher<ChannelCreateEvent, SBDError> {
        let publisher = PassthroughSubject<ChannelCreateEvent, SBDError>()
        createChannel(withName: name, isDistinct: isDistinct, userIds: userIds, coverImage: coverImage, coverImageName: coverImageName, data: data, customType: customType, progressHandler: { (bytesSent, totalBytesSent, totalExpectedBytesToSend) in
            publisher.send(.progress(bytesSent, totalBytesSent, totalExpectedBytesToSend))
        }) { (channel, error) in
            guard let channel = channel, error == nil else {
                publisher.send(completion: .failure(error!))
                return
            }
            
            publisher.send(.created(channel))
            publisher.send(completion: .finished)
        }
        
        return publisher.eraseToAnyPublisher()
    }
    
    public static func createDistinctChannelIfNotExist(with params: SBDGroupChannelParams) -> AnyPublisher<ChannelCreateEvent, SBDError> {
        Future<ChannelCreateEvent, SBDError> { promise in
            createDistinctChannelIfNotExist(with: params) { (channel, isCreated, error) in
                guard let channel = channel, error == nil else {
                    return promise(.failure(error!))
                }
                promise(.success(.createdDistinct(channel, isCreated)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func update(with name: String? = nil, isDistinct: Bool = true, coverImage: Data? = nil, coverImageName: String, data: String? = nil, operatorUserIds: [String]? = nil, customType: String? = nil) -> AnyPublisher<ChannelCreateEvent, SBDError> {
        let publisher = PassthroughSubject<ChannelCreateEvent, SBDError>()
        update(withName: name, isDistinct: isDistinct, coverImage: coverImage, coverImageName: coverImageName, data: data, customType: customType, progressHandler: { (bytesSent, totalBytesSent, totalExpectedBytesToSend) in
            publisher.send(.progress(bytesSent, totalBytesSent, totalExpectedBytesToSend))
        }) { (channel, error) in
            guard let channel = channel, error == nil else {
                publisher.send(completion: .failure(error!))
                return
            }
            
            publisher.send(.created(channel))
            publisher.send(completion: .finished)
        }

        return publisher.eraseToAnyPublisher()
    }
    
    public func refresh() -> AnyPublisher<Void, SBDError> {
        Future<Void, SBDError> { [weak self] promise in
            self?.refresh() { error in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func addReaction(with message: SBDBaseMessage, key: String) -> AnyPublisher<SBDReactionEvent, SBDError> {
        Future<SBDReactionEvent, SBDError> { [weak self] promise in
            self?.addReaction(with: message, key: key, completionHandler: { (event, error) in
                guard let event = event, error == nil else {
                    return promise(.failure(error!))
                }
                
                promise(.success(event))
            })
        }
        .eraseToAnyPublisher()
    }
    
    public func deleteReaction(with message: SBDBaseMessage, key: String) -> AnyPublisher<SBDReactionEvent, SBDError> {
        Future<SBDReactionEvent, SBDError> { [weak self] promise in
            self?.deleteReaction(with: message, key: key, completionHandler: { (event, error) in
                guard let event = event, error == nil else {
                    return promise(.failure(error!))
                }
                
                promise(.success(event))
            })
        }
        .eraseToAnyPublisher()
    }
}
    
extension SBDOpenChannel {
    public static func createChannel() -> AnyPublisher<ChannelCreateEvent, SBDError> {
        Future<ChannelCreateEvent, SBDError> { promise in
            createChannel() { (channel, error) in
                guard let channel = channel, error == nil else {
                    return promise(.failure(error!))
                }
                promise(.success(.created(channel)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public static func createChannel(with name: String? = nil, channelUrl: String? = nil, coverUrl: String? = nil, data: String? = nil, operatorUserIds: [String]? = nil, customType: String? = nil) -> AnyPublisher<ChannelCreateEvent, SBDError> {
        Future<ChannelCreateEvent, SBDError> { promise in
            createChannel(withName: name, channelUrl: channelUrl, coverUrl: coverUrl, data: data, operatorUserIds: operatorUserIds, customType: customType) { (channel, error) in
                guard let channel = channel, error == nil else {
                    return promise(.failure(error!))
                }
                promise(.success(.created(channel)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public static func createChannel(with name: String? = nil, channelUrl: String? = nil, coverImage: Data, coverImageName: String, data: String? = nil, operatorUserIds: [String]? = nil, customType: String? = nil) -> AnyPublisher<ChannelCreateEvent, SBDError> {
        let publisher = PassthroughSubject<ChannelCreateEvent, SBDError>()
        createChannel(withName: name, channelUrl: channelUrl, coverImage: coverImage, coverImageName: coverImageName, data: data, operatorUserIds: operatorUserIds, customType: customType, progressHandler: { (bytesSent, totalBytesSent, totalExpectedBytesToSend) in
            publisher.send(.progress(bytesSent, totalBytesSent, totalExpectedBytesToSend))
        }) { (channel, error) in
            guard let channel = channel, error == nil else {
                publisher.send(completion: .failure(error!))
                return
            }
            
            publisher.send(.created(channel))
            publisher.send(completion: .finished)
        }

        return publisher.eraseToAnyPublisher()
    }
    
    public func update(with name: String? = nil, coverImage: Data? = nil, coverImageName: String, data: String? = nil, operatorUserIds: [String]? = nil, customType: String? = nil) -> AnyPublisher<ChannelCreateEvent, SBDError> {
        let publisher = PassthroughSubject<ChannelCreateEvent, SBDError>()
        update(withName: name, coverImage: coverImage, coverImageName: coverImageName, data: data, operatorUserIds: operatorUserIds, customType: customType, progressHandler: { (bytesSent, totalBytesSent, totalExpectedBytesToSend) in
            publisher.send(.progress(bytesSent, totalBytesSent, totalExpectedBytesToSend))
        }) { (channel, error) in
            guard let channel = channel, error == nil else {
                publisher.send(completion: .failure(error!))
                return
            }
            
            publisher.send(.created(channel))
            publisher.send(completion: .finished)
        }

        return publisher.eraseToAnyPublisher()
    }
    
    public static func getWithUrl(_ channelUrl: String) -> AnyPublisher<SBDOpenChannel, SBDError> {
        Future<SBDOpenChannel, SBDError> { promise in
            getWithUrl(channelUrl) { (channel, error) in
                guard let channel = channel, error == nil else {
                    return promise(.failure(error!))
                }
                
                promise(.success(channel))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func enter() -> AnyPublisher<Void, SBDError> {
        Future<Void, SBDError> { [weak self] promise in
            self?.enter() { error in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func exitChannel() -> AnyPublisher<Void, SBDError> {
        Future<Void, SBDError> { [weak self] promise in
            self?.exitChannel() { error in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func refresh() -> AnyPublisher<Void, SBDError> {
        Future<Void, SBDError> { [weak self] promise in
            self?.refresh() { error in
                guard error == nil else {
                    return promise(.failure(error!))
                }
                
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
}
