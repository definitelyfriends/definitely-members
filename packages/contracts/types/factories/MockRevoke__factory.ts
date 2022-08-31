/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../common";
import type { MockRevoke, MockRevokeInterface } from "../MockRevoke";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "definitelyMemberships_",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "addToDenyList",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "definitelyMemberships",
    outputs: [
      {
        internalType: "contract IDefinitelyMemberships",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "removeFromDenyList",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "id",
        type: "uint256",
      },
      {
        internalType: "bool",
        name: "addToDenyList_",
        type: "bool",
      },
    ],
    name: "revoke",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];

const _bytecode =
  "0x608060405234801561001057600080fd5b506040516102bf3803806102bf83398101604081905261002f91610054565b600080546001600160a01b0319166001600160a01b0392909216919091179055610084565b60006020828403121561006657600080fd5b81516001600160a01b038116811461007d57600080fd5b9392505050565b61022c806100936000396000f3fe608060405234801561001057600080fd5b506004361061004c5760003560e01c8063215048cd1461005157806340a73c13146100665780637d491b3114610079578063b903364c146100a8575b600080fd5b61006461005f3660046101ba565b6100bb565b005b6100646100743660046101ea565b61011e565b60005461008c906001600160a01b031681565b6040516001600160a01b03909116815260200160405180910390f35b6100646100b63660046101ba565b610188565b60005460405163f817242d60e01b81526001600160a01b0383811660048301529091169063f817242d906024015b600060405180830381600087803b15801561010357600080fd5b505af1158015610117573d6000803e3d6000fd5b5050505050565b600054604051632a8c348f60e21b81526004810184905282151560248201526001600160a01b039091169063aa30d23c90604401600060405180830381600087803b15801561016c57600080fd5b505af1158015610180573d6000803e3d6000fd5b505050505050565b60005460405163752d547760e01b81526001600160a01b0383811660048301529091169063752d5477906024016100e9565b6000602082840312156101cc57600080fd5b81356001600160a01b03811681146101e357600080fd5b9392505050565b600080604083850312156101fd57600080fd5b823591506020830135801515811461021457600080fd5b80915050925092905056fea164736f6c634300080f000a";

type MockRevokeConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: MockRevokeConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class MockRevoke__factory extends ContractFactory {
  constructor(...args: MockRevokeConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    definitelyMemberships_: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<MockRevoke> {
    return super.deploy(
      definitelyMemberships_,
      overrides || {}
    ) as Promise<MockRevoke>;
  }
  override getDeployTransaction(
    definitelyMemberships_: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(definitelyMemberships_, overrides || {});
  }
  override attach(address: string): MockRevoke {
    return super.attach(address) as MockRevoke;
  }
  override connect(signer: Signer): MockRevoke__factory {
    return super.connect(signer) as MockRevoke__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): MockRevokeInterface {
    return new utils.Interface(_abi) as MockRevokeInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): MockRevoke {
    return new Contract(address, _abi, signerOrProvider) as MockRevoke;
  }
}