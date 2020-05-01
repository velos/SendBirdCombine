//
//  SendbirdDelegateProxy.swift
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

import Foundation
import Combine
import SendBirdSDK

public enum ChannelEvent {
    case received(SBDBaseMessage)
    case updated(SBDBaseMessage)
    case messageDeleted(Int64)
    case receivedMention(SBDBaseMessage)
    case readReceiptUpdated
    case deliveryReceiptUpdated
    case typingStatusUpdated
    case receivedInvitation([SBDUser]?, SBDUser?)
    case declinedInvitation(SBDUser, SBDUser?)
    case userJoined(SBDUser)
    case userLeft(SBDUser)
    case userMuted(SBDUser)
    case userUnmuted(SBDUser)
    case userBanned(SBDUser)
    case userUnbanned(SBDUser)
    case frozen
    case unfrozen
    case changed
    case hidden
    case createdMetaData([String : String]?)
    case updatedMetaData([String : String]?)
    case deletedMetaData([String]?)
    case createdMetaCounters([String : NSNumber]?)
    case updatedMetaCounters([String : NSNumber]?)
    case deletedMetaCounters([String]?)
    case reactionUpdated(SBDReactionEvent)
    case operatorsUpdated

}

public enum UserEvent {
    case discoveredFriends([SBDUser]?)
    case updatedTotalUnreadMessageCount(Int32, [String : NSNumber]?)
}

public enum ConnectionEvent {
    case started
    case succeeded
    case failed
    case canceled
}

private struct ChannelEventInfo {
    let channel: SBDBaseChannel
    let event: ChannelEvent
}

public class SendbirdDelegateProxy: NSObject {
    public static let sharedInstance = SendbirdDelegateProxy()
    
    private let channelPassthrough: PassthroughSubject<ChannelEventInfo, Never>
    private let userPassthrough: PassthroughSubject<UserEvent, Never>
    private let connectionPassthrough: PassthroughSubject<ConnectionEvent, Never>
    
    public let userPublisher: AnyPublisher<UserEvent, Never>
    public let connectionPublisher: AnyPublisher<ConnectionEvent, Never>
    
    deinit {
        SBDMain.removeAllChannelDelegates()
        SBDMain.removeAllUserEventDelegates()
        SBDMain.removeAllConnectionDelegates()
    }

    override init() {
        channelPassthrough = PassthroughSubject<ChannelEventInfo, Never>()
        userPassthrough = PassthroughSubject<UserEvent, Never>()
        connectionPassthrough = PassthroughSubject<ConnectionEvent, Never>()
        
        userPublisher = userPassthrough.eraseToAnyPublisher()
        connectionPublisher = connectionPassthrough.eraseToAnyPublisher()
        
        super.init()
        
        SBDMain.add(self as SBDChannelDelegate, identifier: "SendbirdDelegateProxy")
    }
    
    public func channelPublisher(for channel: SBDBaseChannel) -> AnyPublisher<ChannelEvent, Never> {
        return channelPassthrough
            .filter { $0.channel == channel }
            .map { $0.event }
            .eraseToAnyPublisher()
    }
}

extension SendbirdDelegateProxy: SBDChannelDelegate {
    public func channel(_ sender: SBDBaseChannel, didReceive message: SBDBaseMessage) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.received(message)))
    }
    
    public func channel(_ sender: SBDBaseChannel, didUpdate message: SBDBaseMessage) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.updated(message)))
    }
    
    public func channel(_ sender: SBDBaseChannel, messageWasDeleted messageId: Int64) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.messageDeleted(messageId)))
    }
    
    public func channel(_ channel: SBDBaseChannel, didReceiveMention message: SBDBaseMessage) {
        channelPassthrough.send(ChannelEventInfo(channel: channel, event: ChannelEvent.receivedMention(message)))
    }
    
    public func channelDidUpdateReadReceipt(_ sender: SBDGroupChannel) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.readReceiptUpdated))
    }
    
    public func channelDidUpdateDeliveryReceipt(_ sender: SBDGroupChannel) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.deliveryReceiptUpdated))
    }
    
    public func channelDidUpdateTypingStatus(_ sender: SBDGroupChannel) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.typingStatusUpdated))
    }
    
    public func channel(_ sender: SBDGroupChannel, didReceiveInvitation invitees: [SBDUser]?, inviter: SBDUser?) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.receivedInvitation(invitees, inviter)))
    }
    
    public func channel(_ sender: SBDGroupChannel, didDeclineInvitation invitee: SBDUser, inviter: SBDUser?) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.declinedInvitation(invitee, inviter)))
    }
    
    public func channel(_ sender: SBDGroupChannel, userDidJoin user: SBDUser) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.userJoined(user)))
    }
    
    public func channel(_ sender: SBDGroupChannel, userDidLeave user: SBDUser) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.userLeft(user)))
    }
    
    public func channel(_ sender: SBDOpenChannel, userDidEnter user: SBDUser) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.userJoined(user)))
    }
    
    public func channel(_ sender: SBDOpenChannel, userDidExit user: SBDUser) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.userLeft(user)))
    }
    
    public func channel(_ sender: SBDBaseChannel, userWasMuted user: SBDUser) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.userMuted(user)))
    }
    
    public func channel(_ sender: SBDBaseChannel, userWasUnmuted user: SBDUser) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.userUnmuted(user)))
    }
    
    public func channel(_ sender: SBDBaseChannel, userWasBanned user: SBDUser) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.userBanned(user)))
    }
    
    public func channel(_ sender: SBDBaseChannel, userWasUnbanned user: SBDUser) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.userUnbanned(user)))
    }
    
    public func channelWasFrozen(_ sender: SBDBaseChannel) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.frozen))
    }
    
    public func channelWasUnfrozen(_ sender: SBDBaseChannel) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.unfrozen))
    }
    
    public func channelWasChanged(_ sender: SBDBaseChannel) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.changed))
    }
    
    public func channelWasHidden(_ sender: SBDGroupChannel) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.hidden))
    }
    
    public func channel(_ sender: SBDBaseChannel, createdMetaData: [String : String]?) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.createdMetaData(createdMetaData)))
    }
    
    public func channel(_ sender: SBDBaseChannel, updatedMetaData: [String : String]?) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.updatedMetaData(updatedMetaData)))
    }
    
    public func channel(_ sender: SBDBaseChannel, deletedMetaDataKeys: [String]?) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.deletedMetaData(deletedMetaDataKeys)))
    }
    
    public func channel(_ sender: SBDBaseChannel, createdMetaCounters: [String : NSNumber]?) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.createdMetaCounters(createdMetaCounters)
        ))
    }
    
    public func channel(_ sender: SBDBaseChannel, updatedMetaCounters: [String : NSNumber]?) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.updatedMetaCounters(updatedMetaCounters)))
    }
    
    public func channel(_ sender: SBDBaseChannel, deletedMetaCountersKeys: [String]?) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.deletedMetaCounters(deletedMetaCountersKeys)))
    }
    
    public func channel(_ sender: SBDBaseChannel, updatedReaction reactionEvent: SBDReactionEvent) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.reactionUpdated(reactionEvent)))
    }
    
    public func channelDidUpdateOperators(_ sender: SBDBaseChannel) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: ChannelEvent.operatorsUpdated))
    }
}

extension SendbirdDelegateProxy: SBDUserEventDelegate {
    public func didDiscoverFriends(_ friends: [SBDUser]?) {
        userPassthrough.send(.discoveredFriends(friends))
    }
    
    public func didUpdateTotalUnreadMessageCount(_ totalCount: Int32, totalCountByCustomType: [String : NSNumber]?) {
        userPassthrough.send(.updatedTotalUnreadMessageCount(totalCount, totalCountByCustomType))
    }
}

extension SendbirdDelegateProxy: SBDConnectionDelegate {
    public func didStartReconnection() {
        connectionPassthrough.send(.started)
    }
    
    public func didSucceedReconnection() {
        connectionPassthrough.send(.succeeded)
    }
    
    public func didFailReconnection() {
        connectionPassthrough.send(.failed)
    }
    
    public func didCancelReconnection() {
        connectionPassthrough.send(.canceled)
    }
}
