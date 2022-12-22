import { DocsThemeConfig } from "nextra-theme-docs";

const config: DocsThemeConfig = {
  logo: <img width="48rem" src="/pioneer.png" />,
  useNextSeoProps: () => ({
    titleTemplate: "%s – Pioneer",
  }),
  head: (
    <>
      <meta name="msapplication-TileColor" content="#ffffff" />
      <meta name="theme-color" content="#ffffff" />
      <meta name="viewport" content="width=devppice-width, initial-scale=1.0" />
      <meta httpEquiv="Content-Language" content="en" />
      <meta name="description" content="GraphQL server for Swift" />
      <meta name="og:description" content="GraphQL server for Swift" />
      <meta
        name="twitter:card"
        content="https://pioneer.dexclaimation.com/pioneer-shown.png"
      />
      <meta
        name="twitter:image"
        content="https://pioneer.dexclaimation.com/pioneer-shown.png"
      />
      <meta name="twitter:site:domain" content="dexclaimation.com" />
      <meta name="twitter:url" content="https://pioneer.dexclaimation.com" />
      <meta name="og:title" content="Pioneer" />
      <meta
        name="og:image"
        content="https://pioneer.dexclaimation.com/pioneer-shown.png"
      />
      <meta name="apple-mobile-web-app-title" content="Pioneer" />
      <link rel="icon" href="/pioneer.png" type="image/png" />
    </>
  ),
  project: {
    link: "https://github.com/d-exclaimation/pioneer",
  },
  chat: {
    link: "https://discord.gg/vapor",
  },
  docsRepositoryBase:
    "https://github.com/d-exclaimation/pioneer/tree/main/Documentation",
  footer: {
    text: "© Copyright 2022. d-exclaimation. All rights reserved.",
  },
};

export default config;
