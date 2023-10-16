//
//  Future+Async.swift
//
//
//  Created by Ondřej Veselý on 16.12.2022.
//

import Combine

extension Future where Failure == Error {
    convenience init(asyncFunc: @escaping () async throws -> Output) {
        self.init { promise in
            Task {
                do {
                    let result = try await asyncFunc()
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
}
