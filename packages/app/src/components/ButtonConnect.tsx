import { ConnectKitButton } from "connectkit";
import { useAccount } from "wagmi";
import { useENS } from "../hooks/useENS";
import { Button } from "./Button";

type Props = {
  connectedText?: string;
  notConnectedText?: string;
};

export function ButtonConnect({
  connectedText,
  notConnectedText = "Connect Wallet",
}: Props) {
  const { address: connectedAddress } = useAccount();
  const { displayName } = useENS(connectedAddress);

  return (
    <ConnectKitButton.Custom>
      {({ isConnected, show }) => {
        return (
          <Button onClick={show}>
            {isConnected ? connectedText || displayName : notConnectedText}
          </Button>
        );
      }}
    </ConnectKitButton.Custom>
  );
}
