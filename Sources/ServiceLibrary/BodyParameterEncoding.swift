//
//  BodyParameterEncoding.swift
//
//
//  Created by Ondřej Veselý on 01.12.2022.
//

/// A type used to define how a set of parameters are applied to a `URLRequest`.
public enum BodyParameterEncoding: String {
    /// Sets encoded query string result as the HTTP body of the URL request.
    case formUrlEncoded = "application/x-www-form-urlencoded"

    /// Encodes any JSON compatible object as the HTTP body of the URL request.
    case json = "application/json"
}
