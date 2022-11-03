//
//  Pioneer+IDE.swift
//  Pioneer
//
//  Created by d-exclaimation.
//
import Vapor

extension Pioneer {
    /// Common Handler for GraphQL IDE through HTTP
    /// - Parameter req: The HTTP request being made
    /// - Returns: A response with the GraphQL IDE
    public func ideHandler(req: Request) -> Response {
        switch (playground) {
            case .playground:
                return serve(html: playgroundHtml)
            case .graphiql:
                return serve(html: graphiqlHtml)
            case .sandbox:
                return serve(html: embeddedSandboxHtml)
            case .redirect(to: let cloud):
                return req.redirect(to: cloud.url, type: .permanent)
            case .disable:
                return Response(status: .notFound)
        }
    }

    /// Server HTML through HTTP
    /// - Parameter html: The HTML content
    /// - Returns: A response with the HTML and proper headers
    private func serve(html: String) -> Response {
        return Response(
            status: .ok,
            headers: HTTPHeaders([(HTTPHeaders.Name.contentType.description, "text/html")]),
            body: Response.Body(string: html)
        ) 
    }
}
