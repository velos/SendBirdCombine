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
        Button(action: viewModel.createChannel) {
            Image(systemName: "plus.message.fill")
        }
    }

    var body: some View {
        List(viewModel.channels, id: \.channelUrl) { channel in
            VStack(alignment: .leading) {
                Text("Channel: \(channel.name)")
                    .font(.headline)
                Text("\(viewModel.lastUpdate[channel.channelUrl] ?? "")")
                    .font(.subheadline)
            }
        }
        .listStyle(PlainListStyle())
        .navigationBarTitle("My Channels", displayMode: .inline)
        .navigationBarItems(trailing: addButton)
        .onAppear(perform: viewModel.loadChannels)
    }
}

struct ChannelsListView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelsListView(viewModel: ChannelsViewModel())
    }
}
