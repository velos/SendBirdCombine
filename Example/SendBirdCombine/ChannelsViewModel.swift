//
//  ChannelsViewModel.swift
//  SBCExample
//
//  Created by Zac White on 3/12/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import SendBirdSDK
import SendBirdCombine
import Combine

class ChannelsViewModel: ObservableObject {

    @Published var channels: [SBDGroupChannel] = []
    @Published var lastUpdate: [String: String] = [:]
    @Published var user: SBDUser? = nil

    private var cancellables: Set<AnyCancellable> = Set()

    func loadChannels() {
        guard let query = SBDGroupChannel.createMyGroupChannelListQuery() else {
            return
        }

        let load = connectIfNecessary()
            .flatMap { _ in query.loadNextPage() }
            .catch { _ in Just([]) }
            .share()

        load
            .assign(to: \.channels, on: self)
            .store(in: &cancellables)

        load
            .flatMap { channels in
                return Publishers.MergeMany(channels.map { channel in channel.eventPublisher.map { (channel, $0) } })
            }
            .print("➡️")
            .sink { [weak self] result in
                let (channel, event) = result
                if let eventString = event.eventString {
                    self?.lastUpdate[channel.channelUrl] = eventString
                }
            }
            .store(in: &cancellables)
    }

    func createChannel() {
        connectIfNecessary()
            .flatMap { _ in SBDGroupChannel.createChannel(with: ["other-user"], isDistinct: true) }
            .catch { _ in Empty() }
            .sink { [weak self] createEvent in

                guard let self = self else {
                    return
                }

                switch createEvent {
                case .created(let channel), .createdDistinct(let channel, _):
                    if let groupChannel = channel as? SBDGroupChannel, !self.channels.contains(groupChannel) {
                        self.channels.insert(groupChannel, at: 0)
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    private func connectIfNecessary() -> AnyPublisher<SBDUser, SBDError> {
        guard let currentUser = SBDMain.getCurrentUser() else {
            return SBDMain.connect(userId: "my-user")
                .handleEvents(receiveOutput: { [weak self] user in
                    self?.user = user
                })
                .eraseToAnyPublisher()
        }

        return Just(currentUser)
            .setFailureType(to: SBDError.self)
            .eraseToAnyPublisher()
    }
}
