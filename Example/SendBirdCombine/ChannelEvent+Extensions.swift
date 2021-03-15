//
//  ChannelEvent+Extensions.swift
//  SBCExample
//
//  Created by Zac White on 3/12/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import SendBirdCombine

extension ChannelEvent {
    var eventString: String? {
        switch self {
        case .received(let message):
            return message.message
        case .updated(let message):
            return message.message
        case .messageDeleted:
            return "Message deleted"
        case .receivedMention:
            return "You were mentioned"
        case .readReceiptUpdated:
            return "Read receipt updated"
        case .deliveryReceiptUpdated:
            return "Delivery receipt updated"
        case .typingStatusUpdated:
            return nil
        case .userJoined(let user):
            return "\(user.nickname ?? "?") joined"
        case .userLeft(let user):
            return "\(user.nickname ?? "?") left"
        case .userMuted(let user):
            return "\(user.nickname ?? "?") muted"
        case .userUnmuted(let user):
            return "\(user.nickname ?? "?") unmuted"
        case .userBanned(let user):
            return "\(user.nickname ?? "?") banned"
        case .userUnbanned(let user):
            return "\(user.nickname ?? "?") unbanned"
        case .frozen:
            return "Channel frozen"
        case .unfrozen:
            return "Channel unfrozen"
        case .hidden:
            return "Channel hidden"
        case .reactionUpdated(let reaction):
            return "Reaction \(reaction.key)"
        default:
            return nil
        }
    }
}
