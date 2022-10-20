/* eslint-disable */
import * as types from './graphql';
import { TypedDocumentNode as DocumentNode } from '@graphql-typed-document-node/core';

const documents = {
    "\n  query Inventory($owner: String!) {\n    tokens(where: { owner: $owner }, first: 100) {\n      id\n      tokenURI\n    }\n  }\n": types.InventoryDocument,
};

export function graphql(source: "\n  query Inventory($owner: String!) {\n    tokens(where: { owner: $owner }, first: 100) {\n      id\n      tokenURI\n    }\n  }\n"): (typeof documents)["\n  query Inventory($owner: String!) {\n    tokens(where: { owner: $owner }, first: 100) {\n      id\n      tokenURI\n    }\n  }\n"];

export function graphql(source: string): unknown;
export function graphql(source: string) {
  return (documents as any)[source] ?? {};
}

export type DocumentType<TDocumentNode extends DocumentNode<any, any>> = TDocumentNode extends DocumentNode<  infer TType,  any>  ? TType  : never;