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

    @State private var isAnimating: Bool = false

    private var typingAnimation: Animation {
        Animation.easeInOut(duration: 1.0)
            .repeatForever(autoreverses: true)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("\(name)")
                    .font(.headline)
                Text("\(lastMessage ?? "")")
                    .font(.callout)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            Spacer()
            if isTyping {
                Image(systemName: "ellipsis")
                    .opacity(isAnimating ? 0.25 : 1.0)
                    .animation(typingAnimation)
                    .onAppear { isAnimating = true }
                    .onDisappear { isAnimating = false }
            }
        }
    }
}

struct ChannelsListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChannelsListView(viewModel: ChannelsViewModel(userId: "my-user"))

            ChannelRow(name: "Test Channel", lastMessage: "A really long last message that has to probably go to two lines", isTyping: true)
                .previewLayout(.sizeThatFits)
            ChannelRow(name: "Test Channel", lastMessage: "A really long last message that has to probably go to two lines", isTyping: false)
                .previewLayout(.sizeThatFits)
            ChannelRow(name: "Test Channel", lastMessage: nil, isTyping: true)
                .previewLayout(.sizeThatFits)
            ChannelRow(name: "Test Channel", lastMessage: nil, isTyping: false)
                .previewLayout(.sizeThatFits)
        }
    }
}
