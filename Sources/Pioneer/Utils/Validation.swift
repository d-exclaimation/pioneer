//
//  Validation.swift
//  Pioneer
//
//  Created by d-exclaimation on 09:58.
//

import GraphQL

/// Function that describe a validation rule for an operation
public typealias ValidationRule = (ValidationContext) -> Visitor

public extension Pioneer {
    /// Validation strategy to add custom rules that is executed before any resolver is executed
    enum Validations: @unchecked Sendable, ExpressibleByArrayLiteral, ExpressibleByNilLiteral {
        public init(nilLiteral _: ()) {
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

        public func callAsFunction(using schema: GraphQLSchema, for gql: GraphQLRequest) -> [GraphQLError] {
            guard let ast = gql.ast else { return [] }
            switch self {
            case .none:
                return []
            case let .specified(rules):
                return validate(schema: schema, ast: ast, rules: rules)
            case let .computed(compute):
                return validate(schema: schema, ast: ast, rules: compute(gql))
            }
        }
    }
}
