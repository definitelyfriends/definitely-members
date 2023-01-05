import styled from "@emotion/styled";
import { ChangeEvent, useEffect, useState } from "react";
import { useEnsAddress } from "wagmi";
import { useIsDefMember } from "../hooks/useIsDefMember";
import { useIsMounted } from "../hooks/useIsMounted";
import { useSendInvite } from "../hooks/useSendInvite";
import { Button } from "./Button";
import { Card } from "./Card";
import { Input } from "./Input";
import { LoadingIndicator } from "./LoadingIndicator";
import { Mono } from "./Typography";

const Form = styled.form`
  display: grid;
  grid-template-columns: 1fr;
  grid-gap: 1em;

  @media (min-width: 40rem) {
    grid-template-columns: 1fr max-content;
    align-items: start;
  }
`;

export function InviteCard() {
  const isMounted = useIsMounted();

  const [toInput, setToInput] = useState("");
  const [toInputLoading, setToInputLoading] = useState(false);
  const [debouncedToInput, setDebouncedToInput] = useState("");
  const [toInputError, setToInputError] = useState("");

  const { isDefMember: isToDefMember } = useIsDefMember({
    address: debouncedToInput as `0x${string}`,
    onSettled: (isMember, error) => {
      if (error) {
        setToInputError("Invalid address");
      }
      if (isMember) {
        setToInputError("Already a DEF member");
      }
      setToInputLoading(false);
    },
  });

  useEffect(() => {
    setToInputError("");
    if (toInput === "") {
      setToInputLoading(false);
    }
    const tick = setTimeout(() => {
      setDebouncedToInput(toInput.trim());
    }, 300);

    return () => clearTimeout(tick);
  }, [toInput]);

  const onInputChange = (event: ChangeEvent<HTMLInputElement>) => {
    setToInput(event.target.value);
    setToInputLoading(true);
  };

  const { data: toAddress } = useEnsAddress({ name: debouncedToInput });

  const { invite, inviteTx } = useSendInvite({
    to: toAddress || ("0x0" as `0x${string}`),
    onPrepareError: (error) => {
      console.log(error);
    },
  });

  return (
    <Card title="Send Invite">
      <Mono margin="0 0 1">
        Invite a new member to DEF and they can claim whenever they're ready.
      </Mono>

      {isMounted && (
        <Form
          onSubmit={(e) => {
            e.preventDefault();
            invite.write?.();
          }}
        >
          <>
            <div>
              <Input
                value={toInput}
                onChange={onInputChange}
                suffixEl={toInputLoading ? <LoadingIndicator /> : null}
                errorMessage={toInputError}
                placeholder="ENS or address"
              />
            </div>

            <Button
              disabled={Boolean(
                !invite.write || inviteTx.error || isToDefMember
              )}
              type="submit"
              isLoading={invite.isLoading || inviteTx.isLoading}
            >
              {inviteTx.isLoading ? (
                <Mono as="span">Claiming&hellip;</Mono>
              ) : (
                "Send invite"
              )}
            </Button>
          </>
        </Form>
      )}
    </Card>
  );
}
