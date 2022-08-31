/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BigNumberish,
  BytesLike,
  CallOverrides,
  PopulatedTransaction,
  Signer,
  utils,
} from "ethers";
import type { FunctionFragment, Result } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type {
  TypedEventFilter,
  TypedEvent,
  TypedListener,
  OnEvent,
  PromiseOrValue,
} from "./common";

export interface MerkleInterface extends utils.Interface {
  functions: {
    "getProof(bytes32[],uint256)": FunctionFragment;
    "getRoot(bytes32[])": FunctionFragment;
    "hashLeafPairs(bytes32,bytes32)": FunctionFragment;
    "log2ceil(uint256)": FunctionFragment;
    "log2ceilBitMagic(uint256)": FunctionFragment;
    "verifyProof(bytes32,bytes32[],bytes32)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "getProof"
      | "getRoot"
      | "hashLeafPairs"
      | "log2ceil"
      | "log2ceilBitMagic"
      | "verifyProof"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "getProof",
    values: [PromiseOrValue<BytesLike>[], PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "getRoot",
    values: [PromiseOrValue<BytesLike>[]]
  ): string;
  encodeFunctionData(
    functionFragment: "hashLeafPairs",
    values: [PromiseOrValue<BytesLike>, PromiseOrValue<BytesLike>]
  ): string;
  encodeFunctionData(
    functionFragment: "log2ceil",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "log2ceilBitMagic",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "verifyProof",
    values: [
      PromiseOrValue<BytesLike>,
      PromiseOrValue<BytesLike>[],
      PromiseOrValue<BytesLike>
    ]
  ): string;

  decodeFunctionResult(functionFragment: "getProof", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "getRoot", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "hashLeafPairs",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "log2ceil", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "log2ceilBitMagic",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "verifyProof",
    data: BytesLike
  ): Result;

  events: {};
}

export interface Merkle extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: MerkleInterface;

  queryFilter<TEvent extends TypedEvent>(
    event: TypedEventFilter<TEvent>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TEvent>>;

  listeners<TEvent extends TypedEvent>(
    eventFilter?: TypedEventFilter<TEvent>
  ): Array<TypedListener<TEvent>>;
  listeners(eventName?: string): Array<Listener>;
  removeAllListeners<TEvent extends TypedEvent>(
    eventFilter: TypedEventFilter<TEvent>
  ): this;
  removeAllListeners(eventName?: string): this;
  off: OnEvent<this>;
  on: OnEvent<this>;
  once: OnEvent<this>;
  removeListener: OnEvent<this>;

  functions: {
    getProof(
      data: PromiseOrValue<BytesLike>[],
      node: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[string[]]>;

    getRoot(
      data: PromiseOrValue<BytesLike>[],
      overrides?: CallOverrides
    ): Promise<[string]>;

    hashLeafPairs(
      left: PromiseOrValue<BytesLike>,
      right: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<[string] & { _hash: string }>;

    log2ceil(
      x: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    log2ceilBitMagic(
      x: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    verifyProof(
      root: PromiseOrValue<BytesLike>,
      proof: PromiseOrValue<BytesLike>[],
      valueToProve: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<[boolean]>;
  };

  getProof(
    data: PromiseOrValue<BytesLike>[],
    node: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<string[]>;

  getRoot(
    data: PromiseOrValue<BytesLike>[],
    overrides?: CallOverrides
  ): Promise<string>;

  hashLeafPairs(
    left: PromiseOrValue<BytesLike>,
    right: PromiseOrValue<BytesLike>,
    overrides?: CallOverrides
  ): Promise<string>;

  log2ceil(
    x: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  log2ceilBitMagic(
    x: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  verifyProof(
    root: PromiseOrValue<BytesLike>,
    proof: PromiseOrValue<BytesLike>[],
    valueToProve: PromiseOrValue<BytesLike>,
    overrides?: CallOverrides
  ): Promise<boolean>;

  callStatic: {
    getProof(
      data: PromiseOrValue<BytesLike>[],
      node: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<string[]>;

    getRoot(
      data: PromiseOrValue<BytesLike>[],
      overrides?: CallOverrides
    ): Promise<string>;

    hashLeafPairs(
      left: PromiseOrValue<BytesLike>,
      right: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<string>;

    log2ceil(
      x: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    log2ceilBitMagic(
      x: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    verifyProof(
      root: PromiseOrValue<BytesLike>,
      proof: PromiseOrValue<BytesLike>[],
      valueToProve: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<boolean>;
  };

  filters: {};

  estimateGas: {
    getProof(
      data: PromiseOrValue<BytesLike>[],
      node: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getRoot(
      data: PromiseOrValue<BytesLike>[],
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    hashLeafPairs(
      left: PromiseOrValue<BytesLike>,
      right: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    log2ceil(
      x: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    log2ceilBitMagic(
      x: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    verifyProof(
      root: PromiseOrValue<BytesLike>,
      proof: PromiseOrValue<BytesLike>[],
      valueToProve: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    getProof(
      data: PromiseOrValue<BytesLike>[],
      node: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getRoot(
      data: PromiseOrValue<BytesLike>[],
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    hashLeafPairs(
      left: PromiseOrValue<BytesLike>,
      right: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    log2ceil(
      x: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    log2ceilBitMagic(
      x: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    verifyProof(
      root: PromiseOrValue<BytesLike>,
      proof: PromiseOrValue<BytesLike>[],
      valueToProve: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;
  };
}
