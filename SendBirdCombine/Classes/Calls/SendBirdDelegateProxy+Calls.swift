//
//  SendBirdDelegateProxy+Calls.swift
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
import AVKit
import SendBirdSDK
import SendBirdCalls

public enum SendBirdCallEvent {
    case startedRinging(DirectCall)
}

public enum DirectCallEvent {
    case established
    case connected
    case startedReconnecting
    case reconnected
    case remoteAudioSettingsChanged
    case remoteVideoSettingsChanged
    case audioDeviceChanged(AVAudioSession, AVAudioSessionRouteDescription, AVAudioSession.RouteChangeReason)
    case customItemsUpdated([String])
    case customItemsDeleted([String])
    case ended
}

struct DirectCallEventInfo {
    let call: DirectCall
    let event: DirectCallEvent
}

class SendBirdCallsDelegateProxy: NSObject {
    static let sharedInstance = SendBirdCallsDelegateProxy()

    let callPassthrough: PassthroughSubject<SendBirdCallEvent, Never>
    let directCallPassthrough: PassthroughSubject<DirectCallEventInfo, Never>

    deinit {
        SendBirdCall.removeAllDelegates()
    }

    override init() {
        callPassthrough = PassthroughSubject<SendBirdCallEvent, Never>()
        directCallPassthrough = PassthroughSubject<DirectCallEventInfo, Never>()

        super.init()

        SendBirdCall.addDelegate(self, identifier: "SendBirdCallDelegate")
    }
}

extension SendBirdCallsDelegateProxy: SendBirdCallDelegate {
    func didStartRinging(_ call: DirectCall) {
        callPassthrough.send(.startedRinging(call))
    }
}

extension SendBirdCallsDelegateProxy: DirectCallDelegate {
    func didEstablish(_ call: DirectCall) {
        directCallPassthrough.send(DirectCallEventInfo(call: call, event: .established))
    }

    func didConnect(_ call: DirectCall) {
        directCallPassthrough.send(DirectCallEventInfo(call: call, event: .connected))
    }

    func didStartReconnecting(_ call: DirectCall) {
        directCallPassthrough.send(DirectCallEventInfo(call: call, event: .startedReconnecting))
    }

    func didReconnect(_ call: DirectCall) {
        directCallPassthrough.send(DirectCallEventInfo(call: call, event: .reconnected))
    }

    func didRemoteAudioSettingsChange(_ call: DirectCall) {
        directCallPassthrough.send(DirectCallEventInfo(call: call, event: .remoteAudioSettingsChanged))
    }

    func didRemoteVideoSettingsChange(_ call: DirectCall) {
        directCallPassthrough.send(DirectCallEventInfo(call: call, event: .remoteVideoSettingsChanged))
    }

    func didEnd(_ call: DirectCall) {
        directCallPassthrough.send(DirectCallEventInfo(call: call, event: .ended))
    }

    func didAudioDeviceChange(_ call: DirectCall, session: AVAudioSession, previousRoute: AVAudioSessionRouteDescription, reason: AVAudioSession.RouteChangeReason) {
        directCallPassthrough.send(DirectCallEventInfo(call: call, event: .audioDeviceChanged(session, previousRoute, reason)))
    }

    func didUpdateCustomItems(call: DirectCall, updatedKeys: [String]) {
        directCallPassthrough.send(DirectCallEventInfo(call: call, event: .customItemsUpdated(updatedKeys)))
    }

    func didDeleteCustomItems(call: DirectCall, deletedKeys: [String]) {
        directCallPassthrough.send(DirectCallEventInfo(call: call, event: .customItemsDeleted(deletedKeys)))
    }
}
