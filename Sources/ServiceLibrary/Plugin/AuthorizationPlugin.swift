//
//  AuthorizationPlugin.swift
//
//
//  Created by Ondřej Veselý on 01.12.2022.
//

import Foundation

public protocol AuthorizationPlugin {
    /// Called to modify a request before sending.
    func prepare(_ request: URLRequest, service: any ServiceProtocol) -> URLRequest
}
