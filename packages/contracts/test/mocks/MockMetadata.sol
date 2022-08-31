//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@def/interfaces/IDefinitelyMetadata.sol";

contract MockMetadata is IDefinitelyMetadata {
    using Strings for uint256;
    string public baseURI;

    constructor(string memory baseURI_) {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString()) : "";
    }
}
