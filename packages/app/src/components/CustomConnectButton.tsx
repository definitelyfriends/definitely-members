import { ConnectKitButton } from "connectkit";
import { useAccount } from "wagmi";
import { useENS } from "../hooks/useENS";
import { Button } from "./Button";

interface Props {
  notConnectedText?: string;
}

export function CustomConnectButton({
  notConnectedText = "Connect Wallet",
}: Props) {
  const { address: connectedAddress } = useAccount();
  const { displayName } = useENS(connectedAddress);

  return (
    <ConnectKitButton.Custom>
      {({ isConnected, show }) => {
        return (
          <Button onClick={show}>
            {isConnected ? displayName : notConnectedText}
          </Button>
        );
      }}
    </ConnectKitButton.Custom>
  );
}
