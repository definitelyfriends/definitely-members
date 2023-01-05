import { css } from "@emotion/react";
import styled from "@emotion/styled";
import { LoadingIndicator } from "./LoadingIndicator";
import { Subheading } from "./Typography";

const StyledCard = styled.article<{ isLoading: boolean }>`
  border: 1px solid rgba(var(--foreground-alpha), 0.05);
  padding: 1rem;
  border-radius: 0.5rem;

  @media (min-width: 32rem) {
    padding: 2rem;
    border-radius: 1rem;
  }

  ${(p) =>
    p.isLoading &&
    css`
      display: flex;
      justify-content: center;
      align-items: center;
      padding: 2rem;

      @media (min-width: 32rem) {
        padding: 4rem;
      }
    `}
`;

type Props = {
  children?: React.ReactNode;
  title?: string;
  isLoading?: boolean;
};

export function Card({ children, title, isLoading = false }: Props) {
  return (
    <StyledCard isLoading={isLoading}>
      {!isLoading && <Subheading margin="0 0 0.25">{title}</Subheading>}
      {isLoading && <LoadingIndicator />}
      {children}
    </StyledCard>
  );
}
