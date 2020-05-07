//
//  SendBirdDelegateProxy.swift
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
    case createdMetaData([String: String]?)
    case updatedMetaData([String: String]?)
    case deletedMetaData([String]?)
    case createdMetaCounters([String: NSNumber]?)
    case updatedMetaCounters([String: NSNumber]?)
    case deletedMetaCounters([String]?)
    case reactionUpdated(SBDReactionEvent)
    case operatorsUpdated

}

public enum UserEvent {
    case discoveredFriends([SBDUser]?)
    case updatedTotalUnreadMessageCount(Int32, [String: NSNumber]?)
}

public enum ConnectionEvent {
    case started
    case succeeded
    case failed
    case canceled
}

struct ChannelEventInfo {
    let channel: SBDBaseChannel
    let event: ChannelEvent
}

class SendBirdDelegateProxy: NSObject {
    static let sharedInstance = SendBirdDelegateProxy()

    let channelPassthrough: PassthroughSubject<ChannelEventInfo, Never>
    let userPassthrough: PassthroughSubject<UserEvent, Never>
    let connectionPassthrough: PassthroughSubject<ConnectionEvent, Never>

    deinit {
        SBDMain.removeAllChannelDelegates()
        SBDMain.removeAllUserEventDelegates()
        SBDMain.removeAllConnectionDelegates()
    }

    override init() {
        channelPassthrough = PassthroughSubject<ChannelEventInfo, Never>()
        userPassthrough = PassthroughSubject<UserEvent, Never>()
        connectionPassthrough = PassthroughSubject<ConnectionEvent, Never>()

        super.init()

        SBDMain.add(self as SBDChannelDelegate, identifier: "SendbirdChannelDelegateProxy")
        SBDMain.add(self as SBDUserEventDelegate, identifier: "SendbirdUserEventDelegateProxy")
        SBDMain.add(self as SBDConnectionDelegate, identifier: "SendbirdConnectionDelegateProxy")
    }
}

extension SendBirdDelegateProxy: SBDChannelDelegate {
    func channel(_ sender: SBDBaseChannel, didReceive message: SBDBaseMessage) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .received(message)))
    }

    func channel(_ sender: SBDBaseChannel, didUpdate message: SBDBaseMessage) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .updated(message)))
    }

    func channel(_ sender: SBDBaseChannel, messageWasDeleted messageId: Int64) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .messageDeleted(messageId)))
    }

    func channel(_ channel: SBDBaseChannel, didReceiveMention message: SBDBaseMessage) {
        channelPassthrough.send(ChannelEventInfo(channel: channel, event: .receivedMention(message)))
    }

    func channelDidUpdateReadReceipt(_ sender: SBDGroupChannel) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .readReceiptUpdated))
    }

    func channelDidUpdateDeliveryReceipt(_ sender: SBDGroupChannel) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .deliveryReceiptUpdated))
    }

    func channelDidUpdateTypingStatus(_ sender: SBDGroupChannel) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .typingStatusUpdated))
    }

    func channel(_ sender: SBDGroupChannel, didReceiveInvitation invitees: [SBDUser]?, inviter: SBDUser?) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .receivedInvitation(invitees, inviter)))
    }

    func channel(_ sender: SBDGroupChannel, didDeclineInvitation invitee: SBDUser, inviter: SBDUser?) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .declinedInvitation(invitee, inviter)))
    }

    func channel(_ sender: SBDGroupChannel, userDidJoin user: SBDUser) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .userJoined(user)))
    }

    func channel(_ sender: SBDGroupChannel, userDidLeave user: SBDUser) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .userLeft(user)))
    }

    func channel(_ sender: SBDOpenChannel, userDidEnter user: SBDUser) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .userJoined(user)))
    }

    func channel(_ sender: SBDOpenChannel, userDidExit user: SBDUser) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .userLeft(user)))
    }

    func channel(_ sender: SBDBaseChannel, userWasMuted user: SBDUser) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .userMuted(user)))
    }

    func channel(_ sender: SBDBaseChannel, userWasUnmuted user: SBDUser) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .userUnmuted(user)))
    }

    func channel(_ sender: SBDBaseChannel, userWasBanned user: SBDUser) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .userBanned(user)))
    }

    func channel(_ sender: SBDBaseChannel, userWasUnbanned user: SBDUser) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .userUnbanned(user)))
    }

    func channelWasFrozen(_ sender: SBDBaseChannel) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .frozen))
    }

    func channelWasUnfrozen(_ sender: SBDBaseChannel) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .unfrozen))
    }

    func channelWasChanged(_ sender: SBDBaseChannel) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .changed))
    }

    func channelWasHidden(_ sender: SBDGroupChannel) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .hidden))
    }

    func channel(_ sender: SBDBaseChannel, createdMetaData: [String: String]?) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .createdMetaData(createdMetaData)))
    }

    func channel(_ sender: SBDBaseChannel, updatedMetaData: [String: String]?) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .updatedMetaData(updatedMetaData)))
    }

    func channel(_ sender: SBDBaseChannel, deletedMetaDataKeys: [String]?) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .deletedMetaData(deletedMetaDataKeys)))
    }

    func channel(_ sender: SBDBaseChannel, createdMetaCounters: [String: NSNumber]?) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .createdMetaCounters(createdMetaCounters)
        ))
    }

    func channel(_ sender: SBDBaseChannel, updatedMetaCounters: [String: NSNumber]?) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .updatedMetaCounters(updatedMetaCounters)))
    }

    func channel(_ sender: SBDBaseChannel, deletedMetaCountersKeys: [String]?) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .deletedMetaCounters(deletedMetaCountersKeys)))
    }

    func channel(_ sender: SBDBaseChannel, updatedReaction reactionEvent: SBDReactionEvent) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .reactionUpdated(reactionEvent)))
    }

    func channelDidUpdateOperators(_ sender: SBDBaseChannel) {
        channelPassthrough.send(ChannelEventInfo(channel: sender, event: .operatorsUpdated))
    }
}

extension SendBirdDelegateProxy: SBDUserEventDelegate {
    func didDiscoverFriends(_ friends: [SBDUser]?) {
        userPassthrough.send(.discoveredFriends(friends))
    }

    func didUpdateTotalUnreadMessageCount(_ totalCount: Int32, totalCountByCustomType: [String: NSNumber]?) {
        userPassthrough.send(.updatedTotalUnreadMessageCount(totalCount, totalCountByCustomType))
    }
}

extension SendBirdDelegateProxy: SBDConnectionDelegate {
    func didStartReconnection() {
        connectionPassthrough.send(.started)
    }

    func didSucceedReconnection() {
        connectionPassthrough.send(.succeeded)
    }

    func didFailReconnection() {
        connectionPassthrough.send(.failed)
    }

    func didCancelReconnection() {
        connectionPassthrough.send(.canceled)
    }
}
