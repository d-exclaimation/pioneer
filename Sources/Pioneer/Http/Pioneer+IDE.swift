//
//  Pioneer+IDE.swift
//  Pioneer
//
//  Created by d-exclaimation.
//
import Vapor

extension Pioneer {
    /// GraphQL Hosted IDE
    public enum IDE {
        /// GraphQL Playground IDE (only for `subscriptions-graphql-ws`)
        @available(*, deprecated, message: "Use `GraphiQL instead`")
        case playground
        
        /// GraphiQL Browser IDE
        case graphiql
        
        /// Redirect to Apollo Sandbox
        case apolloSandbox
        
        /// Redirect to Banana Cake Pop
        case bananaCakePop
        
        /// Disabled any IDEs
        case disable
    }
    
    /// Apply playground for `GET` on `/playground`.
    func applyPlayground(on router: RoutesBuilder, at path: PathComponent) {
        let graphqlPlayground = """
        <!DOCTYPE html>
        <html>

        <head>
            <meta charset=utf-8/>
            <meta name="viewport"
                  content="user-scalable=no, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, minimal-ui">
            <title>GraphQL Playground</title>
            <link rel="stylesheet" href="//cdn.jsdelivr.net/npm/graphql-playground-react/build/static/css/index.css"/>
            <link rel="shortcut icon" href="//cdn.jsdelivr.net/npm/graphql-playground-react/build/favicon.png"/>
            <script src="//cdn.jsdelivr.net/npm/graphql-playground-react/build/static/js/middleware.js"></script>
        </head>

        <body>
        <div id="root">
            <style>
                body {
                    background-color: rgb(23, 42, 58);
                    font-family: Open Sans, sans-serif;
                    height: 90vh;
                }

                #root {
                    height: 100%;
                    width: 100%;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }

                .loading {
                    font-size: 32px;
                    font-weight: 200;
                    color: rgba(255, 255, 255, .6);
                    margin-left: 20px;
                }

                img {
                    width: 78px;
                    height: 78px;
                }

                .title {
                    font-weight: 400;
                }
            </style>
            <img src='//cdn.jsdelivr.net/npm/graphql-playground-react/build/logo.png' alt=''>
            <div class="loading"> Loading
                <span class="title">GraphQL Playground</span>
            </div>
        </div>
        <script>window.addEventListener('load', function (event) {
            GraphQLPlayground.init(document.getElementById('root'), {
                endpoint: "./\(path)",
                subscriptionEndpoint: "./\(path)/websocket"
            })
        })</script>
        </body>

        </html>
        """
        
        func handler(req: Request) -> Response {
            Response(
                status: .ok,
                headers: HTTPHeaders([(HTTPHeaders.Name.contentType.description, "text/html")]),
                body: Response.Body(string: graphqlPlayground)
            )
        }
        
        router.get("playground", use: handler)
    }
    
    /// Apply GraphiQL for `GET` on `/playground`.
    func applyGraphiQL(on router: RoutesBuilder, at path: PathComponent) {
        let fetcher: String = def {
            switch websocketProtocol {
            case .subscriptionsTransportWs:
                return """
                <script src="https://unpkg.com/subscriptions-transport-ws/browser/client.js" type="application/javascript"></script>
                <script>
                    const url = './\(path)';
                    const subscriptionUrl = window.location.href.replace("playground", "\(path)/websocket").replace("http", "ws");
                
                    const legacyClient = new window.SubscriptionsTransportWs.SubscriptionClient(subscriptionUrl, { reconnect: true });
                
                    const fetcher = GraphiQL.createFetcher({
                        url,
                        legacyClient,
                    });
                    ReactDOM.render(
                        React.createElement(GraphiQL, {
                            fetcher
                        }),
                        document.getElementById('graphiql'),
                    );
                </script>
                """
            case .graphqlWs:
                return """
                <script>
                    const url = './\(path)';
                    const subscriptionUrl = window.location.href.replace("playground", "\(path)/websocket").replace("http", "ws");

                    const fetcher = GraphiQL.createFetcher({
                        url,
                        subscriptionUrl
                    });
                    ReactDOM.render(
                        React.createElement(GraphiQL, {
                            fetcher
                        }),
                        document.getElementById('graphiql'),
                    );
                </script>
                """
            case .disable:
                return """
                <script>
                    const url = './\(path)';

                    const fetcher = GraphiQL.createFetcher({
                        url
                    });
                    ReactDOM.render(
                        React.createElement(GraphiQL, {
                            fetcher
                        }),
                        document.getElementById('graphiql'),
                    );
                </script>
                """
            }
        }
        let graphiql = """
        <!DOCTYPE html>
        <html>
          <head>
            <style>
              body {
                height: 100%;
                margin: 0;
                width: 100%;
                overflow: hidden;
              }

              #graphiql {
                height: 100vh;
              }
            </style>

            <!--
              This GraphiQL example depends on Promise and fetch, which are available in
              modern browsers, but can be "polyfilled" for older browsers.
              GraphiQL itself depends on React DOM.
              If you do not want to rely on a CDN, you can host these files locally or
              include them directly in your favored resource bunder.
            -->
            <script
              crossorigin
              src="https://unpkg.com/react@16/umd/react.development.js"
            ></script>
            <script
              crossorigin
              src="https://unpkg.com/react-dom@16/umd/react-dom.development.js"
            ></script>
            <!--
              These two files can be found in the npm module, however you may wish to
              copy them directly into your environment, or perhaps include them in your
              favored resource bundler.
             -->
            <link rel="stylesheet" href="https://unpkg.com/graphiql/graphiql.min.css" />
          </head>

          <body>
            <div id="graphiql">Loading...</div>
            <script src="https://unpkg.com/graphiql/graphiql.min.js" type="application/javascript"></script>
             <!--
              This line add subscriptions-transport-ws for better protocol options
             -->
            \(fetcher)
          </body>
        </html>
        """
        func handler(req: Request) -> Response {
            Response(
                status: .ok,
                headers: HTTPHeaders([(HTTPHeaders.Name.contentType.description, "text/html")]),
                body: Response.Body(string: graphiql)
            )
        }
        
        router.get("playground", use: handler)
    }
    
    
    func applySandboxRedirect(on router: RoutesBuilder, with target: String) {
        router.get("playground") { req in
            req.redirect(to: target, type: .permanent)
        }
    }
}
