//
//  _app.tsx
//  pioneer-site
//
//  Created by d-exclaimation on 10 Dec 2022
//

import type { AppProps } from "next/app";
import "../styles.css";

export default function App({ Component, pageProps }: AppProps) {
  return <Component {...pageProps} />;
}
