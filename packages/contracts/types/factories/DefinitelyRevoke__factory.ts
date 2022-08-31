/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import {
  Signer,
  utils,
  Contract,
  ContractFactory,
  BigNumberish,
  Overrides,
} from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../common";
import type {
  DefinitelyRevoke,
  DefinitelyRevokeInterface,
} from "../DefinitelyRevoke";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "owner_",
        type: "address",
      },
      {
        internalType: "address",
        name: "definitelyMemberships_",
        type: "address",
      },
      {
        internalType: "uint64",
        name: "minQuorum_",
        type: "uint64",
      },
      {
        internalType: "uint64",
        name: "maxVotes_",
        type: "uint64",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    inputs: [],
    name: "AlreadyDefMember",
    type: "error",
  },
  {
    inputs: [],
    name: "AlreadyVoted",
    type: "error",
  },
  {
    inputs: [],
    name: "CannotCreateProposalForSelf",
    type: "error",
  },
  {
    inputs: [],
    name: "NotDefMember",
    type: "error",
  },
  {
    inputs: [],
    name: "NotProposalInitiator",
    type: "error",
  },
  {
    inputs: [],
    name: "ProposalEnded",
    type: "error",
  },
  {
    inputs: [],
    name: "ProposalInProgress",
    type: "error",
  },
  {
    inputs: [],
    name: "ProposalNotFound",
    type: "error",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "user",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "newOwner",
        type: "address",
      },
    ],
    name: "OwnerUpdated",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "address",
        name: "owner",
        type: "address",
      },
    ],
    name: "ProposalApproved",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "address",
        name: "owner",
        type: "address",
      },
    ],
    name: "ProposalCancelled",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        indexed: false,
        internalType: "bool",
        name: "addToDenyList",
        type: "bool",
      },
    ],
    name: "ProposalCreated",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "address",
        name: "owner",
        type: "address",
      },
    ],
    name: "ProposalDenied",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "cancelProposal",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "definitelyMemberships",
    outputs: [
      {
        internalType: "address",
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
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
      {
        internalType: "bool",
        name: "addToDenyList",
        type: "bool",
      },
    ],
    name: "newProposal",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "owner",
    outputs: [
      {
        internalType: "address",
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
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    name: "proposals",
    outputs: [
      {
        internalType: "address",
        name: "initiator",
        type: "address",
      },
      {
        internalType: "uint8",
        name: "approvalCount",
        type: "uint8",
      },
      {
        internalType: "bool",
        name: "addToDenyList",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "newOwner",
        type: "address",
      },
    ],
    name: "setOwner",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
      {
        internalType: "bool",
        name: "inFavor",
        type: "bool",
      },
    ],
    name: "vote",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "votingConfig",
    outputs: [
      {
        internalType: "uint64",
        name: "minQuorum",
        type: "uint64",
      },
      {
        internalType: "uint64",
        name: "maxVotes",
        type: "uint64",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
];

const _bytecode =
  "0x608060405234801561001057600080fd5b50604051610c3d380380610c3d83398101604081905261002f9161011a565b600080546001600160a01b0319166001600160a01b03861690811782556040518692907f8292fce18fa69edf4db7b94ea2e58241df0ae57f97e0a6c9b29067028bf92d76908290a350600180546001600160a01b039094166001600160a01b031990941693909317909255604080518082019091526001600160401b0391821680825292909116602090910181905260038054680100000000000000009092026001600160801b03199092169092171790555061016e565b80516001600160a01b03811681146100fe57600080fd5b919050565b80516001600160401b03811681146100fe57600080fd5b6000806000806080858703121561013057600080fd5b610139856100e7565b9350610147602086016100e7565b925061015560408601610103565b915061016360608601610103565b905092959194509250565b610ac08061017d6000396000f3fe608060405234801561001057600080fd5b50600436106100885760003560e01c80638315e8cf1161005b5780638315e8cf1461017a5780638da5cb5b1461018d578063c9d27afe146101a0578063e0a8f6f5146101b357600080fd5b8063013cf08b1461008d57806313af4035146100fa578063294e62b91461010f5780637d491b311461014f575b600080fd5b6100cc61009b366004610975565b6002602052600090815260409020546001600160a01b0381169060ff600160a01b8204811691600160a81b90041683565b604080516001600160a01b03909416845260ff90921660208401521515908201526060015b60405180910390f35b61010d6101083660046109a3565b6101c6565b005b60035461012e9067ffffffffffffffff80821691600160401b90041682565b6040805167ffffffffffffffff9384168152929091166020830152016100f1565b600154610162906001600160a01b031681565b6040516001600160a01b0390911681526020016100f1565b61010d6101883660046109c7565b61025e565b600054610162906001600160a01b031681565b61010d6101ae3660046109c7565b610440565b61010d6101c1366004610975565b610806565b6000546001600160a01b031633146102135760405162461bcd60e51b815260206004820152600c60248201526b15539055551213d49256915160a21b604482015260640160405180910390fd5b600080546001600160a01b0319166001600160a01b0383169081178255604051909133917f8292fce18fa69edf4db7b94ea2e58241df0ae57f97e0a6c9b29067028bf92d769190a350565b600180546040516370a0823160e01b81523360048201526001600160a01b03909116906370a0823190602401602060405180830381865afa1580156102a7573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906102cb91906109fc565b106102e957604051633a20139760e01b815260040160405180910390fd5b6001546040516331a9108f60e11b8152600481018490526000916001600160a01b031690636352211e90602401602060405180830381865afa158015610333573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906103579190610a15565b6000848152600260205260409020909150336001600160a01b03831614806103875750326001600160a01b038316145b156103a55760405163336b465b60e21b815260040160405180910390fd5b80546001600160a01b0316156103ce5760405163bf83bdbb60e01b815260040160405180910390fd5b8054600161ff0160a01b0319163360ff60a81b191617600160a81b841515908102919091178255604080516001600160a01b0385168152602081019290925285917f60a8c28da1194a1bf10a79ec2583ed8ee7a7bebe5da70ffa94ac6c84bb1de5ea910160405180910390a250505050565b600180546040516370a0823160e01b81523360048201526001600160a01b03909116906370a0823190602401602060405180830381865afa158015610489573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906104ad91906109fc565b106104cb57604051633a20139760e01b815260040160405180910390fd5b60408051808201825260035467ffffffffffffffff8082168352600160401b90910416602080830191909152600085815260029091529190912080546001600160a01b031661052d5760405163635e873760e01b815260040160405180910390fd5b8151815460ff600160a01b9091041667ffffffffffffffff909116148061056757506020820151600182015467ffffffffffffffff909116145b15610585576040516348f2885560e01b815260040160405180910390fd5b60005b60018201548110156105f857336001600160a01b03168260010182815481106105b3576105b3610a32565b6000918252602090912001546001600160a01b0316036105e657604051637c9a1cf960e01b815260040160405180910390fd5b806105f081610a5e565b915050610588565b506001808201805491820181556000908152602090200180546001600160a01b031916331790558215801561063757508054600160a01b900460ff1615155b1561066f578054819060149061065690600160a01b900460ff16610a77565b91906101000a81548160ff021916908360ff1602179055505b82156106a8578054819060149061068f90600160a01b900460ff16610a94565b91906101000a81548160ff021916908360ff1602179055505b6020820151600182015467ffffffffffffffff9091161480156106e357508151815467ffffffffffffffff909116600160a01b90910460ff16105b1561072b576000546040516001600160a01b03909116815284907fd63e027f476c96878eafb40abfcd1656d73d0c888ebdcd24d5f6407a2540c3a39060200160405180910390a25b8151815467ffffffffffffffff909116600160a01b90910460ff1603610800576000546040516001600160a01b03909116815284907f049c28adfe50bcf1b76fd95273b6a24566b9f377e52fddc653c3355248dad07a9060200160405180910390a26001548154604051632a8c348f60e21b815260048101879052600160a81b90910460ff16151560248201526001600160a01b039091169063aa30d23c90604401600060405180830381600087803b1580156107e757600080fd5b505af11580156107fb573d6000803e3d6000fd5b505050505b50505050565b600180546040516370a0823160e01b81523360048201526001600160a01b03909116906370a0823190602401602060405180830381865afa15801561084f573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061087391906109fc565b1061089157604051633a20139760e01b815260040160405180910390fd5b600081815260026020526040902080546001600160a01b031633146108c957604051639591531d60e01b815260040160405180910390fd5b600082815260026020526040812080546001600160b01b0319168155906108f3600183018261093b565b50506000546040516001600160a01b03909116815282907f74c34a008ce735d9fcf0bd03a9b238d212ad4c441c020661f4ffbb6442645b859060200160405180910390a25050565b5080546000825590600052602060002090810190610959919061095c565b50565b5b80821115610971576000815560010161095d565b5090565b60006020828403121561098757600080fd5b5035919050565b6001600160a01b038116811461095957600080fd5b6000602082840312156109b557600080fd5b81356109c08161098e565b9392505050565b600080604083850312156109da57600080fd5b82359150602083013580151581146109f157600080fd5b809150509250929050565b600060208284031215610a0e57600080fd5b5051919050565b600060208284031215610a2757600080fd5b81516109c08161098e565b634e487b7160e01b600052603260045260246000fd5b634e487b7160e01b600052601160045260246000fd5b600060018201610a7057610a70610a48565b5060010190565b600060ff821680610a8a57610a8a610a48565b6000190192915050565b600060ff821660ff8103610aaa57610aaa610a48565b6001019291505056fea164736f6c634300080f000a";

type DefinitelyRevokeConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: DefinitelyRevokeConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class DefinitelyRevoke__factory extends ContractFactory {
  constructor(...args: DefinitelyRevokeConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    owner_: PromiseOrValue<string>,
    definitelyMemberships_: PromiseOrValue<string>,
    minQuorum_: PromiseOrValue<BigNumberish>,
    maxVotes_: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<DefinitelyRevoke> {
    return super.deploy(
      owner_,
      definitelyMemberships_,
      minQuorum_,
      maxVotes_,
      overrides || {}
    ) as Promise<DefinitelyRevoke>;
  }
  override getDeployTransaction(
    owner_: PromiseOrValue<string>,
    definitelyMemberships_: PromiseOrValue<string>,
    minQuorum_: PromiseOrValue<BigNumberish>,
    maxVotes_: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(
      owner_,
      definitelyMemberships_,
      minQuorum_,
      maxVotes_,
      overrides || {}
    );
  }
  override attach(address: string): DefinitelyRevoke {
    return super.attach(address) as DefinitelyRevoke;
  }
  override connect(signer: Signer): DefinitelyRevoke__factory {
    return super.connect(signer) as DefinitelyRevoke__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): DefinitelyRevokeInterface {
    return new utils.Interface(_abi) as DefinitelyRevokeInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): DefinitelyRevoke {
    return new Contract(address, _abi, signerOrProvider) as DefinitelyRevoke;
  }
}