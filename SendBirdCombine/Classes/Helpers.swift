//
//  Helpers.swift
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
import SendBirdSDK

typealias VoidResult = Result<Void, SBDError>

extension Result {
    static func handle(promise: @escaping Future<Success, Failure>.Promise) -> (Success?, Failure?) -> Void {
        return { value, error in
            let result: Result<Success, Failure>
            if let value = value {
                result = .success(value)
            } else if let error = error {
                result = .failure(error)
            } else {
                fatalError("Either the value or error must not be nil")
            }
            promise(result)
        }
    }

    static func handle(promise: @escaping Future<Void, Failure>.Promise) -> (Failure?) -> Void {
        return { error in
            let result: Result<Void, Failure>
            if let error = error {
                result = .failure(error)
            } else {
                result = .success(())
            }
            promise(result)
        }
    }
}
