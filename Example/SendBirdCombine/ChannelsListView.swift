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
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(channel.name)")
                            .font(.headline)
                        Text("\(viewModel.lastMessage[channel.channelUrl] ?? "")")
                            .font(.subheadline)
                    }
                    Spacer()
                    if viewModel.isTyping[channel.channelUrl] == true {
                        Image(systemName: "ellipsis")
                    }
                }
            }
            .onDelete(perform: viewModel.leaveChannel(at:))
        }
        .listStyle(PlainListStyle())
        .navigationBarTitle("My Channels", displayMode: .inline)
        .navigationBarItems(trailing: addButton)
        .onAppear(perform: viewModel.loadChannels)
    }
}

struct ChannelsListView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelsListView(viewModel: ChannelsViewModel(userId: "my-user"))
    }
}
