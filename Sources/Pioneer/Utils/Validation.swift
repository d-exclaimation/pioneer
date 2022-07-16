//
//  Validation.swift
//  Pioneer
//
//  Created by d-exclaimation on 09:58.
//

import GraphQL

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

        public func callAsFunction(using schema: GraphQLSchema, for gql: GraphQLRequest) throws -> [GraphQLError] {
            let ast = try parse(source: gql.source)
            switch (self) {
            case .none:
                return []
            case .specified(let rules):
                return validate(schema: schema, ast: ast, rules: rules)
            case .computed(let compute):
                return validate(schema: schema, ast: ast, rules: compute(gql))
            }
        }
    }    
}