// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.14;

interface IDefinitelyMemberships {
    function issueMembership(address to) external;

    function isDefMember(address account) external view returns (bool);

    function isOnDenyList(address account) external view returns (bool);
}
