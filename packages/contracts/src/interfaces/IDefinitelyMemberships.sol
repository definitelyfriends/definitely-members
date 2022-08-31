// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.15;

interface IDefinitelyMemberships {
    function issueMembership(address to) external;

    function revokeMembership(uint256 tokenId, bool addToDenyList) external;

    function addAddressToDenyList(address account) external;

    function removeAddressFromDenyList(address account) external;

    function transferMembership(uint256 tokenId, address to) external;

    function isDefMember(address account) external view returns (bool);

    function isOnDenyList(address account) external view returns (bool);
}
