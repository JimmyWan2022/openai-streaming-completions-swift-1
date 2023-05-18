//
//  File.swift
//  
//
//  Created by Jimmy on 2023/5/17.
//

import Foundation

extension OpenAIAzure {
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

//     MARK: - Plain completion

    struct ChatCompletionResponse: Codable {
        struct Choice: Codable {
            var message: Message
        }
        var choices: [Choice]
    }

    public func completeChat(_ completionRequest: ChatCompletionRequest) async throws -> String {
        let request = try createChatRequestAzure(completionRequest: completionRequest,ip: "localhost",port: "9091")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw Errors.invalidResponse(String(data: data, encoding: .utf8) ?? "<failed to decode response>")
        }
        let completionResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard completionResponse.choices.count > 0 else {
            throw Errors.noChoices
        }
        return completionResponse.choices[0].message.content
    }

    // MARK: - Streaming completion

    public func completeChatStreaming(_ completionRequest: ChatCompletionRequest) throws -> AsyncStream<Message> {
        var cr = completionRequest
        cr.stream = true
        let request = try createChatRequestAzure(completionRequest: cr,ip: "localhost",port: "9091")

        return AsyncStream { continuation in
            let src = EventSource(urlRequest: request)

            var message = Message(role: .assistant, content: "")

            src.onComplete { statusCode, reconnect, error in
                continuation.finish()
            }
            src.onMessage { id, event, data in
                guard let data, data != "[DONE]" else { return }
                do {
                    print("Data: \(data)")
                    let decoded = try JSONDecoder().decode(ChatCompletionStreamingResponse.self, from: Data(data.utf8))
                    if let delta = decoded.choices.first?.delta {
                        message.role = delta.role ?? message.role
                        message.content += delta.content ?? ""
                        continuation.yield(message)
                    }
                } catch {
                    print("Chat completion error: \(error)")
                }
            }
            src.connect()
        }
    }
    // MARK: - Streaming completion add url string "https://api.openai.com/v1/chat/completions"

    // http://localhost:9091/api/v1/azureopenai/chat/completions
    public func completeChatStreaming(_ completionRequest: ChatCompletionRequest,apiUrl:String) throws -> AsyncStream<Message> {
        var cr = completionRequest
        cr.stream = true
        let request = try createChatRequestAzure(completionRequest: cr,ip: "localhost",port: "9091")

        return AsyncStream { continuation in
            let src = EventSource(urlRequest: request)

            var message = Message(role: .assistant, content: "")

            src.onComplete { statusCode, reconnect, error in
                continuation.finish()
            }
            src.onMessage { id, event, data in
                guard let data, data != "[DONE]" else { return }
                do {
                    print("Data: \(data)")
                    let decoded = try JSONDecoder().decode(ChatCompletionStreamingResponse.self, from: Data(data.utf8))
                    if let delta = decoded.choices.first?.delta {
                        message.role = delta.role ?? message.role
                        message.content += delta.content ?? ""
                        continuation.yield(message)
                    }
                } catch {
                    print("Chat completion error: \(error)")
                }
            }
            src.connect()
        }
    }
    public func completeChatStreamingWithObservableObject(_ completionRequest: ChatCompletionRequest) throws -> StreamingCompletion {
        let completion = StreamingCompletion()
        Task {
            do {
                for await message in try self.completeChatStreaming(completionRequest) {
                    DispatchQueue.main.async {
                        completion.text = message.content
                    }
                }
                DispatchQueue.main.async {
                    completion.status = .complete
                }
            } catch {
                DispatchQueue.main.async {
                    completion.status = .error
                }
            }
        }
        return completion
    }

//    private struct ChatCompletionStreamingResponse: Codable {
//        struct Choice: Codable {
//            struct MessageDelta: Codable {
//                var role: Message.Role?
//                var content: String?
//            }
//            var delta: MessageDelta
//        }
//        var choices: [Choice]
//    }

    struct ChatCompletionStreamingResponse: Codable {
        let id: String
        let object: String
        let created: Double
        let model: String
        let choices: [Choice]
        let usage: String?
        
        struct Choice: Codable {
            let index: Int
            let finish_reason: String?
            let delta: MessageDelta
            
            struct MessageDelta: Codable {
                let role: Message.Role?
                let content: String?
            }
        }
    }
    
    private func decodeChatStreamingResponse(jsonStr: String) -> String? {
        guard let json = try? JSONDecoder().decode(ChatCompletionStreamingResponse.self, from: Data(jsonStr.utf8)) else {
            return nil
        }
        return json.choices.first?.delta.content
    }
    // http://localhost:9091/api/v1/azureopenai/chat/completions
    private func createChatRequestAzure(completionRequest: ChatCompletionRequest,ip:String,port:String) throws -> URLRequest {
//        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        let url = URL(string: "http://"+ip+":"+port+"/api/v1/azureopenai/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(completionRequest)
        return request
    }
    private func createChatRequestAzure(completionRequest: ChatCompletionRequest,apiUrl:String) throws -> URLRequest {
//      let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        let url = URL(string: apiUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(completionRequest)
        return request
    }
}
