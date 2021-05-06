//
//  CustomError.swift
//  TrackerTest
//
//  Created by Stepan on 23.04.2021.
//

import Foundation

enum CustomError: LocalizedError {
    case wrongRequest
    case parseError
    case messageError(description: String)
    
    var errorDescription: String? {
        switch self {
        case .wrongRequest:
            return "Network request is wrong. Please try to look for definition of another word."
        case .parseError:
            return "Something went unexpected while parsing. Please try again."
        case let .messageError(description: description):
            return description
        }
    }
}
