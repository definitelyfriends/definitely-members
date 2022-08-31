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

import {IDefinitelyMemberships} from "./interfaces/IDefinitelyMemberships.sol";

/// @title Definitely Invites
/// @author DEF DAO
/// @notice An issuing contract that uses an invites mechanism so that existing DEF members
///         can invite new people to DEF. It uses a cooldown system so invites can't be
///         spammed over and over.
contract DefinitelyInvites {
    /* ------------------------------------------------------------------------
       S T O R A G E    
    ------------------------------------------------------------------------ */

    /// @dev The main membership contract that issues NFTs
    IDefinitelyMemberships public definitelyMemberships;

    /// @dev Used to prevent spam invites
    uint256 public inviteCooldown;

    /// @dev A per account cooldown timer
    mapping(address => uint256) public memberLastSentInvite;

    /// @dev Allows a member to set an address that can claim a membership later
    mapping(address => bool) public inviteAvailable;

    /* ------------------------------------------------------------------------
       E V E N T S    
    ------------------------------------------------------------------------ */

    event MemberInvited(address indexed invited, address indexed invitedBy);
    event InviteClaimed(address indexed invited);

    /* ------------------------------------------------------------------------
       E R R O R S    
    ------------------------------------------------------------------------ */

    error InviteOnCooldown();
    error NoInviteToClaim();
    error NotDefMember();

    /* ------------------------------------------------------------------------
       M O D I F I E R S    
    ------------------------------------------------------------------------ */

    /// @dev Reverts if an invite is currently on cooldown
    modifier whenInviteNotOnCooldown() {
        if (memberLastSentInvite[msg.sender] + inviteCooldown < block.timestamp)
            revert InviteOnCooldown();
        _;
    }

    modifier whileInviteAvailable() {
        if (inviteAvailable[msg.sender]) revert NoInviteToClaim();
        _;
    }

    modifier whileDefMember(address from) {
        if (!definitelyMemberships.isDefMember(from)) revert NotDefMember();
        _;
    }

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    constructor(address definitelyMemberships_, uint256 inviteCooldown_) {
        definitelyMemberships = IDefinitelyMemberships(definitelyMemberships_);
        inviteCooldown = inviteCooldown_;
    }

    /* ------------------------------------------------------------------------
       S E N D I N G   I N V I T E S    
    ------------------------------------------------------------------------ */

    /// @notice Send an invite to an address that can be claimed at a later time
    function sendClaimableInvite(address to)
        external
        whileDefMember(msg.sender)
        whenInviteNotOnCooldown
    {
        inviteAvailable[to] = true;
        _startInviteCooldown(msg.sender);
        emit MemberInvited(to, msg.sender);
    }

    /// @notice Send an invite token directly to an address, skipping the claim step
    function sendImediateInvite(address to)
        external
        whileDefMember(msg.sender)
        whenInviteNotOnCooldown
    {
        definitelyMemberships.issueMembership(to);
        _startInviteCooldown(msg.sender);
        emit MemberInvited(to, msg.sender);
    }

    /// @dev Starts the invite cooldown for an address
    function _startInviteCooldown(address inviter) internal {
        memberLastSentInvite[inviter] = block.timestamp;
    }

    /* ------------------------------------------------------------------------
       C L A I M I N G   I N V I T E S
    ------------------------------------------------------------------------ */

    /// @notice Allows someone to claim their invite if they have one available
    function claimInvite() external whileInviteAvailable {
        definitelyMemberships.issueMembership(msg.sender);
        emit InviteClaimed(msg.sender);
        // We don't really need to remove the available invite, but it's nice to clean up
        inviteAvailable[msg.sender] = false;
    }
}
