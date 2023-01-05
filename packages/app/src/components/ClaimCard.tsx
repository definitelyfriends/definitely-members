import styled from "@emotion/styled";
import Link from "next/link";
import { useAccount } from "wagmi";
import { useClaimMembership } from "../hooks/useClaimMembership";
import { useEtherscan } from "../hooks/useEtherscan";
import { useIsDefMember } from "../hooks/useIsDefMember";
import { useIsMounted } from "../hooks/useIsMounted";
import { useMerkleProof } from "../hooks/useMerkleProof";
import { Button } from "./Button";
import { ButtonConnect } from "./ButtonConnect";
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

export function ClaimCard() {
  const isMounted = useIsMounted();
  const { getTransactionUrl } = useEtherscan();

  const { address } = useAccount();

  const { isDefMember, refetch: refetchMemberStatus } = useIsDefMember({
    address,
  });

  const { isLoading: isLoadingProof, error } = useMerkleProof({
    address,
  });

  const { claim, claimTx } = useClaimMembership({
    onTxSuccess: () => refetchMemberStatus(),
  });

  const errorMessage = error instanceof Error ? error.message : "";

  return (
    <Card>
      <>
        <Subheading>Claim Membership</Subheading>
        <Mono margin="0.25 0 1">
          Claim your NFT for DEF DAO if you submitted your address in Discord.
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
                isLoading={
                  isLoadingProof || claim.isLoading || claimTx.isLoading
                }
              >
                {claimTx.isLoading ? (
                  <Mono as="span">Claiming&hellip;</Mono>
                ) : isDefMember ? (
                  "Already in DEF"
                ) : (
                  "Claim"
                )}
              </Button>

              {error && errorMessage && <Mono subdued>{errorMessage}</Mono>}
            </>
          </Form>
        ) : (
          <ButtonConnect />
        )}

        {claim.data && (
          <Mono margin="0.5 0 0" subdued>
            <Link href={getTransactionUrl(claim.data.hash) || ""}>
              View transaction on explorer
            </Link>
          </Mono>
        )}
      </>
    </Card>
  );
}
