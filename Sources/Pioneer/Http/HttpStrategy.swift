//
//  HttpStrategy.swift
//  Pioneer
//
//  Created by d-exclaimation on 4:30 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation

extension Pioneer {
    public enum HTTPStrategy {
        case onlyPost, onlyGet
        case queryOnlyGet, mutationOnlyPost
        case splitQueryAndMutation
    }
}