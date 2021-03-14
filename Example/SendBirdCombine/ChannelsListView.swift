//
//  ChannelsListView.swift
//  SBCExample
//
//  Created by Zac White on 3/12/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import SwiftUI

struct ChannelsListView: View {
    @ObservedObject var viewModel: ChannelsViewModel

    var addButton: some View {
        Button {
            viewModel.createChannel(with: ["other-user"])
        } label: {
            Image(systemName: "plus.message.fill")
        }
    }

    var body: some View {
        List {
            ForEach(viewModel.channels, id: \.channelUrl) { channel in
                ChannelRow(
                    name: channel.name,
                    lastMessage: viewModel.lastMessage[channel.channelUrl],
                    isTyping: viewModel.isTyping[channel.channelUrl] == true
                )
            }
            .onDelete(perform: viewModel.leaveChannels(at:))
        }
        .listStyle(PlainListStyle())
        .navigationBarTitle("My Channels", displayMode: .inline)
        .navigationBarItems(trailing: addButton)
        .onAppear(perform: viewModel.loadChannels)
    }
}

struct ChannelRow: View {

    let name: String
    let lastMessage: String?
    let isTyping: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(name)")
                    .font(.headline)
                Text("\(lastMessage ?? "")")
                    .font(.subheadline)
            }
            Spacer()
            if isTyping {
                Image(systemName: "ellipsis")
            }
        }
    }
}

struct ChannelsListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChannelsListView(viewModel: ChannelsViewModel(userId: "my-user"))

            ChannelRow(name: "Test Channel", lastMessage: "last message", isTyping: true)
            ChannelRow(name: "Test Channel", lastMessage: "last message", isTyping: false)
            ChannelRow(name: "Test Channel", lastMessage: nil, isTyping: true)
            ChannelRow(name: "Test Channel", lastMessage: nil, isTyping: false)
        }
    }
}
