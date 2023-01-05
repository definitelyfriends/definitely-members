import styled from "@emotion/styled";
import Link from "next/link";
import { useEtherscan } from "../hooks/useEtherscan";
import { INVITES_CONTRACT } from "../utils/contracts";
import { Mono, Subheading } from "./Typography";

const Card = styled.article`
  border: 1px solid rgba(var(--foreground-alpha), 0.05);
  padding: 1rem;
  border-radius: 0.5rem;

  @media (min-width: 32rem) {
    padding: 2rem;
    border-radius: 1rem;
  }
`;

export function InviteCard() {
  const { getAddressUrl } = useEtherscan();

  return (
    <Card>
      <Subheading>Invite Member</Subheading>
      <Mono margin="0.25 0 1" uppercase subdued>
        UI coming soon
      </Mono>

      <Mono margin="0.25 0 0">
        For now, you can use the{" "}
        <Link href={getAddressUrl(INVITES_CONTRACT.address) || ""}>
          invites contract
        </Link>{" "}
        directly on Etherscan if you already have a DEF NFT. Go to the "write
        contract" tab and use the "sendImmediateInvite" function with the
        address of the person you want to invite to DEF.
      </Mono>
    </Card>
  );
}
