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
    @Published var lastMessage: [String: String] = [:]
    @Published var isTyping: [String: Bool] = [:]
    @Published var user: SBDUser? = nil

    private var cancellables: Set<AnyCancellable> = Set()
    private var channelUpdates: AnyCancellable?

    private let userId: String
    init(userId: String) {
        self.userId = userId
    }

    func loadChannels() {
        guard let query = SBDGroupChannel.createMyGroupChannelListQuery() else {
            return
        }

        $channels
            .map { channels in
                Publishers.MergeMany(
                    channels.map { channel in
                        channel.eventPublisher
                            .map { (channel, $0) }
                            .prepend((channel, .received(channel.lastMessage ?? SBDBaseMessage())))
                    }
                )
            }
            .switchToLatest()
            .sink { [weak self] result in
                let (channel, event) = result
                if let eventString = event.eventString {
                    self?.lastMessage[channel.channelUrl] = eventString
                }

                if case .typingStatusUpdated = event {
                    self?.isTyping[channel.channelUrl] = channel.isTyping()
                }
            }.store(in: &cancellables)

        connectIfNecessary()
            .flatMap { _ in query.loadNextPage() }
            .catch { _ in Just([]) }
            .assign(to: \.channels, on: self)
            .store(in: &cancellables)
    }

    func createChannel(with userIds: [String]) {
        connectIfNecessary()
            .flatMap { _ in SBDGroupChannel.createChannel(with: userIds, isDistinct: true) }
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

    func leaveChannel(at indexSet: IndexSet) {
        let leavePublishers = indexSet.map { index -> AnyPublisher<Result<SBDGroupChannel, SBDError>, Never> in
            let channel = channels[index]
            let publisher: AnyPublisher<Void, SBDError> = channel.leave()

            return publisher
                .map { _ in
                    return Result<SBDGroupChannel, SBDError>.success(channel)
                }
                .catch { error -> AnyPublisher<Result<SBDGroupChannel, SBDError>, Never> in
                    return Just<Result<SBDGroupChannel, SBDError>>(.failure(error))
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }

        Publishers.MergeMany(leavePublishers)
            .sink { [weak self] result in
                switch result {
                case .success(let channel):
                    self?.channels.removeAll(where: { $0.channelUrl == channel.channelUrl })
                case .failure:
                    break
                }
            }
            .store(in: &cancellables)
    }

    private func connectIfNecessary() -> AnyPublisher<SBDUser, SBDError> {
        guard let currentUser = SBDMain.getCurrentUser() else {
            return SBDMain.connect(userId: userId)
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
