//
//  File.swift
//  
//
//  Created by Jimmy on 2023/5/17.
//

import Foundation


public struct OpenAIAzure {
    
    var api_type: String = "azure"
    var api_base: String?
    var api_version: String?
    var api_key: String?

    public init(
                api_type: String ,
                api_base: String? = nil,
                api_version: String? = nil,
                api_key: String? = nil) {
        self.api_type = api_type
        self.api_base = api_base
        self.api_version = api_version
        self.api_key = api_key
    }
    public init(
                api_base: String? = nil,
                api_version: String? = nil,
                api_key: String? = nil) {
        self.api_base = api_base
        self.api_version = api_version
        self.api_key = api_key
    }
}

extension OpenAIAzure {
    enum Errors: Error {
        case noChoices
        case invalidResponse(String)
        case noApiKey
    }
}
