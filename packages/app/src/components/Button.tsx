import { css, keyframes } from "@emotion/react";
import styled from "@emotion/styled";
import { LoadingIndicator } from "./LoadingIndicator";
import { Mono, monoStyles } from "./Typography";

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  children: React.ReactNode;
  isLoading?: boolean;
  loadingMessage?: string;
}

export const buttonReset = css`
  font-weight: normal;
  line-height: 1.5;
  text-decoration: none;
  text-align: center;
  color: var(--foreground);
  -webkit-appearance: none;
  -moz-appearance: none;
  outline: none;
  overflow: hidden;
  background: transparent;
  cursor: pointer;
  transition: color 150ms ease-in-out, opacity 150ms ease-in-out;
`;

const slide = keyframes`
  0% { transform: translateX(-100%); }
	100% { transform: translateX(100%); }
`;

const StyledButton = styled.button<ButtonProps>`
  ${monoStyles};
  ${buttonReset};

  position: relative;
  background: var(--foreground);
  color: var(--background);
  padding: 1rem 1.5rem;
  border-radius: 1rem;
  position: relative;
  overflow: hidden;

  &:after {
    content: "";
    top: 0;
    left: 0;
    opacity: 0;
    transform: translateX(100%);
    width: 100%;
    height: 100%;
    position: absolute;
    z-index: 1;
    animation: ${slide} 2.4s ease-in-out infinite;
    transition: opacity 150ms ease-in-out;
    background: linear-gradient(
      to right,
      rgba(var(--background-alpha), 0) 0%,
      rgba(var(--background-alpha), 0.24) 50%,
      rgba(var(--background-alpha), 0) 100%
    );
  }

  &:hover&:not(:disabled):after {
    opacity: 1;
  }

  &:disabled {
    background: var(--background-emphasis);
    color: rgba(var(--foreground-alpha), 0.48);
    cursor: not-allowed;
  }

  ${(p) =>
    p.isLoading &&
    css`
      &,
      &:disabled {
        color: transparent;
        cursor: not-allowed;
      }
    `}
`;

const LoadingWrapper = styled.span`
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1em;
  color: rgba(var(--foreground-alpha), 0.64);
`;

export function Button({
  children,
  isLoading,
  loadingMessage,
  ...props
}: ButtonProps) {
  return (
    <StyledButton
      {...props}
      isLoading={isLoading}
      disabled={isLoading || props.disabled}
    >
      {isLoading && (
        <LoadingWrapper>
          <LoadingIndicator />
          {loadingMessage && <Mono as="span">{loadingMessage}</Mono>}
        </LoadingWrapper>
      )}
      {children}
    </StyledButton>
  );
}
