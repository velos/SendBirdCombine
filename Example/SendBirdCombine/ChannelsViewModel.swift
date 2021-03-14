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
        setUpChannelsBinding()
    }

    /// Sets up a binding so that whenever the channels Published array is updated,
    /// eventPublishers will be subscribed for each channel so we get channel status
    /// updates like the last message and the typing status.
    private func setUpChannelsBinding() {
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
            .switchToLatest() // ensure previous publishers are canceled
            .sink { [weak self] result in
                let (channel, event) = result
                if let eventString = event.eventString {
                    self?.lastMessage[channel.channelUrl] = eventString
                }

                if case .typingStatusUpdated = event {
                    self?.isTyping[channel.channelUrl] = channel.isTyping()
                }
            }
            .store(in: &cancellables)
    }

    func loadChannels() {
        guard let query = SBDGroupChannel.createMyGroupChannelListQuery() else {
            return
        }

        // connect and load an initial page from the my channels query.
        // assign the result to the channels array.
        connectIfNecessary()
            .flatMap { _ in query.loadNextPage() }
            .catch { _ in Just([]) }
            .assign(to: \.channels, on: self)
            .store(in: &cancellables)
    }

    /// Creates a distinct channel with the given user IDs and updates the channels array if successful.
    /// - Parameter userIds: The user IDs to invite to the channel
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

    /// Leaves all the channels at the index in the passed in IndexSet
    /// - Parameter indexSet: The indexes of channels which should be left
    func leaveChannels(at indexSet: IndexSet) {

        // compile a list of leave publishers, which return the success or failure as a Result
        // so these can't fail.
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

        // merge all the unfailable publishers and remove channels from the channels array for each
        // that succeeds.
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

    /// Connects to SendBird if necessary and outputs the SBDUser if successful.
    /// - Returns: A publisher which outputs the current user's SBDUser immediately if logged in, or logs and and outputs it.
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
