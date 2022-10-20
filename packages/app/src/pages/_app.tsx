import { Global } from "@emotion/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { AppProps } from "next/app";
import { EthereumProviders } from "../components/EthereumProviders";
import { globalStyle } from "../components/GlobalStyle";
import SocialMeta from "../components/SocialMeta";

export const queryClient = new QueryClient();

export default function MyApp({ Component, pageProps }: AppProps) {
  return (
    <>
      <SocialMeta />
      <Global styles={globalStyle} />
      <EthereumProviders>
        <QueryClientProvider client={queryClient}>
          <Component {...pageProps} />
        </QueryClientProvider>
      </EthereumProviders>
    </>
  );
}
