import styled from "@emotion/styled";
import Link from "next/link";
import { useAccount } from "wagmi";
import { useClaimInvite } from "../hooks/useClaimInvite";
import { useEtherscan } from "../hooks/useEtherscan";
import { useIsDefMember } from "../hooks/useIsDefMember";
import { useIsMounted } from "../hooks/useIsMounted";
import { Button } from "./Button";
import { ButtonConnect } from "./ButtonConnect";
import { Card } from "./Card";
import { Mono } from "./Typography";

const Form = styled.form`
  display: grid;
  grid-template-columns: 1fr;
  grid-gap: 1em;

  @media (min-width: 40rem) {
    grid-template-columns: max-content 1fr;
    align-items: center;
    grid-gap: 2em;
  }
`;

export function ClaimInviteCard() {
  const isMounted = useIsMounted();
  const { getTransactionUrl } = useEtherscan();

  const { address } = useAccount();
  const { isDefMember, refetch: refetchMemberStatus } = useIsDefMember({
    address,
  });

  const { hasInviteAvailable, claim, claimTx } = useClaimInvite({
    onTxSuccess: () => refetchMemberStatus(),
  });

  return (
    <Card title="Claim Invite">
      <Mono margin="0.25 0 1">
        Claim your DEF Membership if another member has invited you.
      </Mono>

      {isMounted && address ? (
        <Form
          onSubmit={(e) => {
            e.preventDefault();
            claim.write?.();
          }}
        >
          <>
            <Button
              disabled={Boolean(!claim.write || claimTx.error)}
              type="submit"
              isLoading={claim.isLoading || claimTx.isLoading}
            >
              {claimTx.isLoading ? (
                <Mono as="span">Claiming&hellip;</Mono>
              ) : isDefMember ? (
                "Already in DEF"
              ) : (
                "Claim"
              )}
            </Button>

            {hasInviteAvailable === false && !isDefMember && (
              <Mono subdued>No invite available</Mono>
            )}
          </>
        </Form>
      ) : (
        <ButtonConnect notConnectedText="Connect to claim" />
      )}

      {claim.data && (
        <Mono margin="0.5 0 0" subdued>
          <Link href={getTransactionUrl(claim.data.hash) || ""}>
            View transaction on explorer
          </Link>
        </Mono>
      )}
    </Card>
  );
}
