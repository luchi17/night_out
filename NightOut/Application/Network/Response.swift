//
//  Response.swift
//  AFLLive
//
//  Created by Pablo.Sanchez on 17/8/22.
//  Copyright © 2022 Telstra. All rights reserved.
//

import Foundation

public struct Response {
    /// The status code of the response.
    public let statusCode: Int

    /// The response data.
    public let data: Data

    /// The original URLRequest for the response.
    public let request: URLRequest?

    /// The HTTPURLResponse object.
    public let response: HTTPURLResponse?
}
