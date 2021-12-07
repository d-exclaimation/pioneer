//
//  EnvironmentVariables.swift
//  pioneer-integration-test
//
//  Created by d-exclaimation on 3:32 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import Vapor

extension Environment {
    /// Setup an environment by specifying the information required
    ///
    /// - Parameters:
    ///   - port: PORT used for Vapor application, default to 4000
    ///   - host: Host used, default to "localhost"
    ///   - env: Runtime environment
    /// - Returns: A Environment for Vapor application
    public static func specified(
        port: Int = 4000,
        host: String = "localhost",
        env: String = "development"
    ) throws -> Environment {
        let build = CommandLine.arguments.first ?? ""
        return try .detect(arguments: [
            build, "serve", "--env", env, "--port", "\(port)", "--hostname", host
        ])
    }
}
