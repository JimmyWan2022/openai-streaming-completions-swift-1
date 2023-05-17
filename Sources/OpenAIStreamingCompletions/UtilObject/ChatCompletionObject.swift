//
//  File.swift
//  
//
//  Created by Jimmy on 2023/5/17.
//

import Foundation

public struct ChatCompletionRequest: Codable {
    var messages: [Message]
    var model: String
    var max_tokens: Int = 1500
    var temperature: Double = 0.2
    var stream = false
    var stop: [String]?

    public init(messages: [Message], model: String = "gpt-3.5-turbo", max_tokens: Int = 1500, temperature: Double = 0.2, stop: [String]? = nil) {
        self.messages = messages
        self.model = model
        self.max_tokens = max_tokens
        self.temperature = temperature
        self.stop = stop
    }
}

struct ChatCompletionResponse: Codable {
    struct Choice: Codable {
        var message: Message
    }
    var choices: [Choice]
}

public struct Message: Equatable, Codable, Hashable {
    public enum Role: String, Equatable, Codable, Hashable {
        case system
        case user
        case assistant
    }

    public var role: Role
    public var content: String

    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
}


public struct ChatCompletionStreamingResponse: Codable {
    struct Choice: Codable {
        struct MessageDelta: Codable {
            var role: Message.Role?
            var content: String?
        }
        var delta: MessageDelta
    }
    var choices: [Choice]
}

