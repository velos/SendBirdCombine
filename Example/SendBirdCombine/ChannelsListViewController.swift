//
//  ChannelsListViewController.swift
//  SendBirdCombine
//
//  Created by zac on 03/31/2020.
//  Copyright (c) 2020 zac. All rights reserved.
//

import UIKit
import SendBirdCombine
import SendBirdSDK
import Combine

class ChannelsListViewController: UITableViewController {

    private let viewModel = ChannelsViewModel()
    private var cancellables: Set<AnyCancellable> = Set()

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.$channels
            .sink { channels in
                print("channels: \(channels)")
            }
            .store(in: &cancellables)

        viewModel.loadChannels()
    }
}

