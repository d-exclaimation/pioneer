//
//  Validation.swift
//  Pioneer
//
//  Created by d-exclaimation on 09:58.
//

import class GraphQL.ValidationContext
import struct GraphQL.Visitor

/// Function that describe a validation rule for an operation
public typealias ValidationRule = @Sendable (ValidationContext) -> Visitor

extension Pioneer {
    /// Validation strategy to add custom rules that is executed before any resolver is executed
    public enum Validations: ExpressibleByArrayLiteral, ExpressibleByNilLiteral, Sendable {
        public init(nilLiteral: ()) {
            self = .none
        }

        public init(arrayLiteral elements: ValidationRule...) {
            self = .specified(elements)
        }

        /// No rules, skip validation
        case none

        /// Multiple constant rules
        case specified([ValidationRule])

        /// Multiple rules computed from each operation
        case computed(@Sendable (GraphQLRequest) -> [ValidationRule])
    }    
}