import { Global } from "@emotion/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { AppProps } from "next/app";
import { globalStyle } from "../components/GlobalStyle";
import { SocialMeta } from "../components/SocialMeta";
import { Web3Provider } from "../components/Web3Provider";

export const queryClient = new QueryClient();

export default function MyApp({ Component, pageProps }: AppProps) {
  return (
    <>
      <SocialMeta />
      <Global styles={globalStyle} />
      <Web3Provider>
        <QueryClientProvider client={queryClient}>
          <Component {...pageProps} />
        </QueryClientProvider>
      </Web3Provider>
    </>
  );
}
