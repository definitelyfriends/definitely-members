"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MockMetadata__factory = void 0;
/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
const ethers_1 = require("ethers");
const _abi = [
    {
        inputs: [
            {
                internalType: "string",
                name: "baseURI_",
                type: "string",
            },
        ],
        stateMutability: "nonpayable",
        type: "constructor",
    },
    {
        inputs: [],
        name: "baseURI",
        outputs: [
            {
                internalType: "string",
                name: "",
                type: "string",
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
        ],
        name: "tokenURI",
        outputs: [
            {
                internalType: "string",
                name: "",
                type: "string",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
];
const _bytecode = "0x608060405234801561001057600080fd5b5060405161073038038061073083398101604081905261002f91610058565b600061003b82826101b0565b505061026f565b634e487b7160e01b600052604160045260246000fd5b6000602080838503121561006b57600080fd5b82516001600160401b038082111561008257600080fd5b818501915085601f83011261009657600080fd5b8151818111156100a8576100a8610042565b604051601f8201601f19908116603f011681019083821181831017156100d0576100d0610042565b8160405282815288868487010111156100e857600080fd5b600093505b8284101561010a57848401860151818501870152928501926100ed565b8284111561011b5760008684830101525b98975050505050505050565b600181811c9082168061013b57607f821691505b60208210810361015b57634e487b7160e01b600052602260045260246000fd5b50919050565b601f8211156101ab57600081815260208120601f850160051c810160208610156101885750805b601f850160051c820191505b818110156101a757828155600101610194565b5050505b505050565b81516001600160401b038111156101c9576101c9610042565b6101dd816101d78454610127565b84610161565b602080601f83116001811461021257600084156101fa5750858301515b600019600386901b1c1916600185901b1785556101a7565b600085815260208120601f198616915b8281101561024157888601518255948401946001909101908401610222565b508582101561025f5787850151600019600388901b60f8161c191681555b5050505050600190811b01905550565b6104b28061027e6000396000f3fe608060405234801561001057600080fd5b50600436106100365760003560e01c80636c0360eb1461003b578063c87b56dd14610059575b600080fd5b61004361006c565b6040516100509190610291565b60405180910390f35b6100436100673660046102c4565b6100fa565b60008054610079906102dd565b80601f01602080910402602001604051908101604052809291908181526020018280546100a5906102dd565b80156100f25780601f106100c7576101008083540402835291602001916100f2565b820191906000526020600020905b8154815290600101906020018083116100d557829003601f168201915b505050505081565b6060600080805461010a906102dd565b9050116101265760405180602001604052806000815250610152565b600061013183610158565b604051602001610142929190610333565b6040516020818303038152906040525b92915050565b60608160000361017f5750506040805180820190915260018152600360fc1b602082015290565b8160005b81156101a95780610193816103f3565b91506101a29050600a83610422565b9150610183565b60008167ffffffffffffffff8111156101c4576101c4610436565b6040519080825280601f01601f1916602001820160405280156101ee576020820181803683370190505b5090505b84156102595761020360018361044c565b9150610210600a86610463565b61021b906030610477565b60f81b8183815181106102305761023061048f565b60200101906001600160f81b031916908160001a905350610252600a86610422565b94506101f2565b949350505050565b60005b8381101561027c578181015183820152602001610264565b8381111561028b576000848401525b50505050565b60208152600082518060208401526102b0816040850160208701610261565b601f01601f19169190910160400192915050565b6000602082840312156102d657600080fd5b5035919050565b600181811c908216806102f157607f821691505b60208210810361031157634e487b7160e01b600052602260045260246000fd5b50919050565b60008151610329818560208601610261565b9290920192915050565b600080845481600182811c91508083168061034f57607f831692505b6020808410820361036e57634e487b7160e01b86526022600452602486fd5b8180156103825760018114610397576103c4565b60ff19861689528415158502890196506103c4565b60008b81526020902060005b868110156103bc5781548b8201529085019083016103a3565b505084890196505b5050505050506103d48185610317565b95945050505050565b634e487b7160e01b600052601160045260246000fd5b600060018201610405576104056103dd565b5060010190565b634e487b7160e01b600052601260045260246000fd5b6000826104315761043161040c565b500490565b634e487b7160e01b600052604160045260246000fd5b60008282101561045e5761045e6103dd565b500390565b6000826104725761047261040c565b500690565b6000821982111561048a5761048a6103dd565b500190565b634e487b7160e01b600052603260045260246000fdfea164736f6c634300080f000a";
const isSuperArgs = (xs) => xs.length > 1;
class MockMetadata__factory extends ethers_1.ContractFactory {
    constructor(...args) {
        if (isSuperArgs(args)) {
            super(...args);
        }
        else {
            super(_abi, _bytecode, args[0]);
        }
    }
    deploy(baseURI_, overrides) {
        return super.deploy(baseURI_, overrides || {});
    }
    getDeployTransaction(baseURI_, overrides) {
        return super.getDeployTransaction(baseURI_, overrides || {});
    }
    attach(address) {
        return super.attach(address);
    }
    connect(signer) {
        return super.connect(signer);
    }
    static createInterface() {
        return new ethers_1.utils.Interface(_abi);
    }
    static connect(address, signerOrProvider) {
        return new ethers_1.Contract(address, _abi, signerOrProvider);
    }
}
exports.MockMetadata__factory = MockMetadata__factory;
MockMetadata__factory.bytecode = _bytecode;
MockMetadata__factory.abi = _abi;
