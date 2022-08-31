/**
                                                      ...:--==***#@%%-
                                             ..:  -*@@@@@@@@@@@@@#*:  
                               -:::-=+*#%@@@@@@*-=@@@@@@@@@@@#+=:     
           .::---:.         +#@@@@@@@@@@@@@%*+-. -@@@@@@+..           
    .-+*%@@@@@@@@@@@#-     -@@@@@@@@@@%#*=:.    :@@@@@@@#%@@@@@%:     
 =#@@@@@@@@@@@@@@@@@@@%.   %@@@@@@-..           *@@@@@@@@@@@@%*.      
-@@@@@@@@@#*+=--=#@@@@@%  +@@@@@@%*#%@@@%*=-.. .@@@@@@@%%*+=:         
 :*@@@@@@*       .@@@@@@.*@@@@@@@@@@@@*+-      =%@@@@%                
  =@@@@@@.       *@@@@@%:@@@@@@*==-:.          =@@@@@:                
 .@@@@@@=      =@@@@@@%.*@@@@@=   ..::--=+*=+*+=@@@@=                 
 #@@@@@*    .+@@@@@@@* .+@@@@@#%%@@@@@@@@#+:.  =#@@=                  
 @@@@@%   :*@@@@@@@*:  .#@@@@@@@@@@@@@%#:       ---                   
:@@@@%. -%@@@@@@@+.     +@@@@@%#*+=:.                                 
+@@@%=*@@@@@@@*:        =*:                                           
:*#+%@@@@%*=.                                                         
 :+##*=:.

*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "@solmate/auth/Owned.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IDefinitelyMemberships} from "./interfaces/IDefinitelyMemberships.sol";

/// @title Definitely Family
/// @author DEF DAO
/// @notice Allows existing members (prior to this membership token) to claim a membership
///         token. It uses a merkle proof for the existing members.
contract DefinitelyFamily is Owned {
    using MerkleProof for bytes32[];

    /// @dev The main membership contract that issues NFTs
    IDefinitelyMemberships public definitelyMemberships;

    /// @dev Uses a merkle proof for existing members prior to this contract
    bytes32 public existingMembersRoot;

    /// @dev Whenever a membership is claimed for an existing DEF member
    event MembershipClaimed(address indexed member);

    /// @dev When the msg.sender is not in the merkle root of existing members
    error NotExistingMember();

    constructor(
        address owner,
        address definitelyMemberships_,
        bytes32 existingMembersRoot_
    ) Owned(owner) {
        definitelyMemberships = IDefinitelyMemberships(definitelyMemberships_);
        existingMembersRoot = existingMembersRoot_;
    }

    /// @notice Allows the owner to update the merkleroot of existing DEF members
    /// @param root The merkle root for existing member addresses
    function setExistingMembersClaimRoot(bytes32 root) external onlyOwner {
        existingMembersRoot = root;
    }

    /// @notice Allows existing members (prior to this contract deploy) to claim their NFT
    /// @dev Requires the existing list of members to be set in a merkle root upon deploy
    /// @param proof A merkle proof containing eligible addresses
    function claimPriorMembership(bytes32[] memory proof) external {
        // Check the address and proof
        if (!proof.verify(existingMembersRoot, keccak256(abi.encodePacked(msg.sender)))) {
            revert NotExistingMember();
        }
        definitelyMemberships.issueMembership(msg.sender);
        emit MembershipClaimed(msg.sender);
    }
}
