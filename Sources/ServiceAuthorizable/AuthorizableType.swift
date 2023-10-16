//
//  AuthorizableType.swift
//
//
//  Created by Ondřej Veselý on 08.01.2023.
//

public enum AuthorizableType: Equatable {
    case none
    case token0
    case token(Resource)
}
