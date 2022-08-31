/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BigNumberish,
  BytesLike,
  CallOverrides,
  ContractTransaction,
  Overrides,
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

export interface MockRevokeInterface extends utils.Interface {
  functions: {
    "addToDenyList(address)": FunctionFragment;
    "definitelyMemberships()": FunctionFragment;
    "removeFromDenyList(address)": FunctionFragment;
    "revoke(uint256,bool)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "addToDenyList"
      | "definitelyMemberships"
      | "removeFromDenyList"
      | "revoke"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "addToDenyList",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "definitelyMemberships",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "removeFromDenyList",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "revoke",
    values: [PromiseOrValue<BigNumberish>, PromiseOrValue<boolean>]
  ): string;

  decodeFunctionResult(
    functionFragment: "addToDenyList",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "definitelyMemberships",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "removeFromDenyList",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "revoke", data: BytesLike): Result;

  events: {};
}

export interface MockRevoke extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: MockRevokeInterface;

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
    addToDenyList(
      account: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    definitelyMemberships(overrides?: CallOverrides): Promise<[string]>;

    removeFromDenyList(
      account: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    revoke(
      id: PromiseOrValue<BigNumberish>,
      addToDenyList_: PromiseOrValue<boolean>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;
  };

  addToDenyList(
    account: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  definitelyMemberships(overrides?: CallOverrides): Promise<string>;

  removeFromDenyList(
    account: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  revoke(
    id: PromiseOrValue<BigNumberish>,
    addToDenyList_: PromiseOrValue<boolean>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    addToDenyList(
      account: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;

    definitelyMemberships(overrides?: CallOverrides): Promise<string>;

    removeFromDenyList(
      account: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;

    revoke(
      id: PromiseOrValue<BigNumberish>,
      addToDenyList_: PromiseOrValue<boolean>,
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {};

  estimateGas: {
    addToDenyList(
      account: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    definitelyMemberships(overrides?: CallOverrides): Promise<BigNumber>;

    removeFromDenyList(
      account: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    revoke(
      id: PromiseOrValue<BigNumberish>,
      addToDenyList_: PromiseOrValue<boolean>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    addToDenyList(
      account: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    definitelyMemberships(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    removeFromDenyList(
      account: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    revoke(
      id: PromiseOrValue<BigNumberish>,
      addToDenyList_: PromiseOrValue<boolean>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;
  };
}
