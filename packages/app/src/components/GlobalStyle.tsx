import { css } from "@emotion/react";

export const globalStyle = css`
  :root {
    --foreground: rgb(0, 0, 0);
    --foreground-alpha: 0, 0, 0;
    --background: rgb(255, 255, 255);
    --background-alpha: 255, 255, 255;
    --background-emphasis: rgba(0, 0, 0, 0.04);
    --font-heading: system, -apple-system, "Helvetica Neue", Helvetica,
      "Segoe UI", Roboto, sans-serif;
    --font-sans: system, -apple-system, "Helvetica Neue", Helvetica, "Segoe UI",
      Roboto, sans-serif;
    --font-mono: SFMono-Regular, SF Mono, Menlo, Consolas, Liberation Mono,
      monospace;
  }

  @media (prefers-color-scheme: dark) {
    :root {
      --foreground: rgb(255, 255, 255);
      --foreground-alpha: 255, 255, 255;
      --background: rgb(0, 0, 0);
      --background-alpha: 0, 0, 0;
      --background-emphasis: rgba(255, 255, 255, 0.1);
    }
  }

  *,
  *:before,
  *:after {
    box-sizing: border-box;
    outline: none;
    margin: 0;
    &:focus-visible {
      outline: 1px dotted var(--foreground);
    }
  }

  html,
  body,
  body > div:first-of-type,
  div#__next {
    height: 100%;
  }

  html,
  body {
    padding: 0;
    margin: 0;
  }

  body {
    font-family: var(--font-sans);
    font-size: 16px;
    line-height: 1.5;
    color: var(--foreground);
    background: var(--background);
    cursor: crosshair;
  }

  /* Button reset */
  button {
    margin: 0;
    padding: 0;
    font-family: inherit;
    font-size: 100%;
    line-height: 1.5;
    overflow: visible;
    text-transform: none;
    border: none;
    cursor: pointer;
  }

  button,
  [type="button"],
  [type="reset"],
  [type="submit"] {
    -webkit-appearance: button;
  }

  a {
    color: var(--foreground);
    text-decoration: underline;
    text-decoration-color: rgba(var(--foreground-alpha), 0.4);

    &:hover {
      text-decoration-color: rgba(var(--foreground-alpha), 0.8);
    }
  }
`;
