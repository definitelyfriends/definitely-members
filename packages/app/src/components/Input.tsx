import { css } from "@emotion/react";
import styled from "@emotion/styled";
import { Mono } from "./Typography";

type InputProps = React.InputHTMLAttributes<HTMLInputElement> & {
  /** An element to show inside the input to the left */
  prefixEl?: React.ReactNode;
  /** An element to show inside the input to the right */
  suffixEl?: React.ReactNode;
  errorMessage?: string;
};

const placeholder = css`
  color: rgba(var(--foreground-alpha), 0.4);
`;

const transition = css`
  transition: color 150ms ease;
`;

interface InputWrapperProps {
  isPlaceholder: boolean;
  hasPrefix: boolean;
  hasSuffix: boolean;
}

const InputWrapper = styled.div<InputWrapperProps>`
  display: flex;
  gap: 0.5rem;
  align-items: center;
  border-radius: 0.5rem;
  border: 1px solid rgba(var(--foreground-alpha), 0.2);
  background: var(--background);
  color: var(--foreground);
  font-family: var(--font-mono);
  font-style: normal;
  font-weight: normal;
  font-size: 0.875rem;
  line-height: 1.5;
  overflow: hidden;

  &:focus-within {
    border-color: rgba(var(--foreground-alpha), 0.8);
  }

  ${transition};
  ${(p) => p.isPlaceholder && placeholder};
  ${(p) =>
    p.hasSuffix &&
    css`
      padding-right: 1.5rem;
    `};
`;

const InputElement = styled.input<{ hasSuffix: boolean }>`
  outline: 0;
  border: none;
  background: transparent;
  font-family: inherit;
  font-style: inherit;
  font-weight: inherit;
  font-size: inherit;
  color: inherit;
  flex: 1;
  height: 100%;
  padding: 1rem;
  padding-left: 1.5rem;

  ${(p) =>
    !p.hasSuffix &&
    css`
      padding-right: 1.5rem;
    `};

  &::placeholder {
    ${placeholder};
  }

  ${transition};
`;

const ErrorMessage = styled(Mono)`
  padding: 0.5rem 1.5rem 0;
`;

export function Input({
  className,
  prefixEl,
  suffixEl,
  errorMessage,
  ...props
}: InputProps) {
  return (
    <>
      <InputWrapper
        className={className}
        isPlaceholder={Boolean(props.value === "")}
        hasPrefix={Boolean(prefixEl)}
        hasSuffix={Boolean(suffixEl)}
      >
        {prefixEl || null}
        <InputElement hasSuffix={Boolean(suffixEl)} {...props} />
        {suffixEl || null}
      </InputWrapper>
      {errorMessage && <ErrorMessage subdued>{errorMessage}</ErrorMessage>}
    </>
  );
}
