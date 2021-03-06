# SendBirdCombine

[![Version](https://img.shields.io/cocoapods/v/SendBirdCombine.svg?style=flat)](https://cocoapods.org/pods/SendBirdCombine)
[![License](https://img.shields.io/cocoapods/l/SendBirdCombine.svg?style=flat)](https://cocoapods.org/pods/SendBirdCombine)
[![Platform](https://img.shields.io/cocoapods/p/SendBirdCombine.svg?style=flat)](https://cocoapods.org/pods/SendBirdCombine)

`SendBirdCombine` is a Swift framework that provides [Combine](https://developer.apple.com/documentation/combine) extensions to the [SendBird SDK](https://github.com/sendbird/sendbird-ios-framework). (Note: This project is not affiliated with Sendbird, Inc.) `SendBird` is an in-app messaging platform that provides an Objective-C based iOS SDK and uses some older design patterns such as delegate-based callbacks. `SendBirdCombine` attempts to provide a modern reactive interface to the SendBird SDK for iOS using Combine, making your code easier to read and maintain.

## Compatibility

SendBirdCombine requires **iOS 13+** and is compatible with **Swift 5** projects.

## Installation

SendBirdCombine is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SendBirdCombine'
```

SendBirdCombine also provides support for SendBird Calls. This isn't included by default due to the large binary size of the SendBirdCalls SDK, but if you wish to include it, add this line to your Podfile instead, which will give you support for the base messaging features in addition to Calls:

```ruby
pod 'SendBirdCombine/Calls'
```

## Usage

SendBirdCombine provides `Combine` publishers to your `SendBird`-enabled messaging app. You may subscribe to these publishers instead of using the default SendBird API functions. For example: 

1. To connect to a SendBird instance:
```swift 
var subscriptions = Set<AnyCancellable>()
...
SBDMain.connect(userId: "sendbirdUserId")
    .sink(receiveCompletion: { completion in
        switch completion {
        case let .failure(error):
            print("Sendbird connection error: \(error)")
        case .finished:
            // do something here after connection call completes
        }
    }, receiveValue: { user in
        // do something here after receiving connected SendBird `SBDUser` object
    })
    .store(in: &subscriptions)
```

2. To send a text message on a channel:
```swift
channel.sendUserMessage("message to send")
    .sink(receiveCompletion: { completion in
        switch completion {
        case let .failure(.generalFailure(error)):
            print("error creating message: \(error)")
        case let .failure(.sendingFailed(message, error)):
            print("error sending message: ", message.messageId, error")
        case .finished:
            // handle successful completion
        }
    }, receiveValue: { status in
        switch status {
        case let .tempMessage(message):
            // handle received temporary placeholder message returned by SendBird
        case let .sentMessage(message):
            // handle successfully sent message returned from SendBird
        default:
            // handle any other type of event here
        }
    })
    .store(in: &subscriptions)
```



3. To listen for channel events:
```swift
channel.eventPublisher
    .sink { event in
        switch event {
        case let .received(message):
            // handle received message in this channel
        case let .messageDeleted(messageId):
            // handle deleted message with messageId in this channel
        case let .userJoined(user):
            // handle user that joined this channel
            ...
        default:
            // handle all other cases we don't currently care about here
        }
    }
    .store(in: &subscriptions)
```

4. The advantages of using Combine become more apparent when you chain multiple operations that would normally require nested closures and/or DispatchGroups. For example, to enter an Open Channel by URL and then simultaneously enter the retrieved channel and also download its metadata - without Combine, the code might look something like:

```swift
SBDOpenChannel.getWithUrl("channelUrl") { (channel, error) in
    var enteredChannel: Bool = false
    var channelMetadata: [String: NSObject]?

    guard let channel = channel, error == nil else {
        if let error = error {
            print("error getting channel: \(error)")
            return
        } else {
            fatalError("error can't be nil")
        }
    }

    let group = DispatchGroup()

    group.enter()
    channel.enter { (error) in
        guard error == nil else {
            if let error = error {
                print("error entering channel: \(error)")
                group.leave()
                return
            } else {
                fatalError("error can't be nil")
            }
        }
        enteredChannel = true
        group.leave()
    }

    group.enter()
    channel.getAllMetaData { (metadata, error) in
        guard let metadata = metadata, error == nil else {
            if let error = error {
                print("error retrieving metadata: \(error)")
                group.leave()
                return
            } else {
                fatalError("error can't be nil")
            }
        }

        channelMetadata = metadata
        group.leave()
    }

    group.notify(queue: .main) {
        guard enteredChannel == true, let metadata = channelMetadata else {
            print("error entering channel and/or retrieving metadata")
            return
        }

        print("entered channel and got metadata: \(metadata)")
    }
}
```

But when you chain these actions in Combine, the code becomes much simpler and easier to read:

```swift
SBDOpenChannel.getWithUrl("channelUrl")
    .flatMap { channel in
        channel.enter().zip(channel.getAllMetaData())
    }
    .sink(receiveCompletion: { (completion) in
        switch completion {
        case .failure(let error):
            print("error: \(error)")
        case .finished:
            print("completed")
        }
    }, receiveValue: { (_, metadata) in
        print("joined and got metadata: \(metadata)")
    })
    .store(in: &subscriptions)
```

5. SendBirdCalls can also be handled using Combine (make sure you include the `SendBirdCombine/Calls` Pod as noted above):

```swift

// Receiving a call
SendBirdCall.eventPublisher
    .sink { [weak self] event in
        // There is currently the only case handled by SendBirdCallDelegate
        guard case .startedRinging(let call) = event else { fatalError() }

        // Accept the call then handle additional events for the duration of the call
        call.accept(with: AcceptParams(callOptions: CallOptions()))
        self?.handle(call: call)
    }
    .store(in: &subscriptions)

// Dialing a call
SendBirdCall.dial(with: DialParams(calleeId: "calleeId"))
    .sink(receiveCompletion: { error in
        switch error {
        case .failure(let error):
            print("error dialing: \(error)")
        case .finished:
            // handle successful completion
        }

    }, receiveValue: { [weak self] call in
        self?.handle(call: call)
    })
    .store(in: &subscriptions)

// Listens for call events
func handle(call: DirectCall) {
    call.eventPublisher
        .sink { event in
            switch event {
            case .connected:
                // handle call connected event
            case .ended:
                // handle call ended event
                ...
            default:
                // handle additional cases
            }
    }
    .store(in: &subscriptions)
}
```

There are many other SendBird SDK functions that have a `Combine` publisher available, please explore the `SendBirdCombine` sources to see them all!

## Author

David Rajan, david@velosmobile.com

## License

**SendBirdCombine** is available under the MIT license. See the LICENSE file for more info.
