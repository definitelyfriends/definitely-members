import styled from "@emotion/styled";
import Link from "next/link";
import { useAccount } from "wagmi";
import { useClaimMembership } from "~hooks/useClaimMembership";
import { useEtherscan } from "~hooks/useEtherscan";
import { useIsDefMember } from "~hooks/useIsDefMember";
import { useIsMounted } from "~hooks/useIsMounted";
import { useMerkleProof } from "~hooks/useMerkleProof";
import { Button } from "~components/Button";
import { ButtonConnect } from "~components/ButtonConnect";
import { Card } from "~components/Card";
import { Input } from "~components/Input";
import { Mono } from "~components/Typography";
import { ChangeEvent, useState } from "react";
import { useCreateProposal } from "~hooks/useCreateProposal";

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

export function CreateProposalCard() {
  const isMounted = useIsMounted();
  const { getTransactionUrl } = useEtherscan();

  const { address } = useAccount();

  const { isDefMember } = useIsDefMember({
    address,
  });

 
  const [description, setDescription] = useState("");
  const [error, setError] = useState("");
  const onDescriptionChange = (event: ChangeEvent<HTMLInputElement>) => {
    if (event.target.value.length > 24) {
      setError("Keep descriptions short");
    }
    setDescription(event.target.value);
  };

  const { propose, proposeTx, proposalId } = useCreateProposal({
    description
  });

  // console.warn(proposalId)

  // const errorMessage = error instanceof Error ? error.message : "";

  return (
    <Card title="Create Proposal">
      <Mono margin="0 0 1">Create a new Governance Proposal on Canto</Mono>

      {isMounted && address ? (
        <form
          onSubmit={(e) => {
            e.preventDefault();
            propose.write?.();
          }}
        >
          <div className="grid-col-span-2">
            <Input
              type="textarea"
              className="w-full"
              value={description}
              onChange={onDescriptionChange}
              placeholder="Describe your proposal"
            />
            <>
              <Button
                disabled={Boolean(!propose.write || proposeTx.error)}
                type="submit"
                isLoading={propose.isLoading || proposeTx.isLoading}
              >
                {proposeTx.isLoading ? (
                  <Mono as="span">Claiming&hellip;</Mono>
                ) : isDefMember ? (
                  "Submit Proposal"
                ) : (
                  "Not a Member"
                )}
              </Button>

              {error && <Mono subdued>{error}</Mono>}
            </>
          </div>
        </form>
      ) : (
        <ButtonConnect notConnectedText="Connect to claim" />
      )}

      {propose.data && (
        <Mono margin="0.5 0 0" subdued>
          <Link href={getTransactionUrl(propose.data.hash) || ""}>
            View transaction on explorer
          </Link>
        </Mono>
      )}
    </Card>
  );
}
