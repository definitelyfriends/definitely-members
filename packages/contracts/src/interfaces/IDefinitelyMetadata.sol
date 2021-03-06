// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

interface IDefinitelyMetadata {
    function tokenURI(uint256 id) external view returns (string memory);
}
