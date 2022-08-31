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
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IDefinitelyMemberships} from "./interfaces/IDefinitelyMemberships.sol";

/// @title Definitely Revoke
/// @author DEF DAO
/// @notice A contract to revoke memberships based on a simple voting mechanism
/// @dev This initial implementation doesn't include `addToDenyList` and `removeFromDenyList` from
///      the memberships contract, however adding to the deny list is possible when creating a new
///      proposal to revoke a membership which is ok for v0.1.
contract DefinitelyRevoke is Owned {
    /* ------------------------------------------------------------------------
       S T O R A G E
    ------------------------------------------------------------------------ */

    /// @dev The main membership contract that issues NFTs
    address public definitelyMemberships;

    /* PROPOSALS ----------------------------------------------------------- */

    /// @dev Allows a member to propose another membership be revoked
    struct Proposal {
        address initiator;
        uint8 approvalCount;
        bool addToDenyList;
        address[] voters;
    }

    /// @dev Keeps track of revoke membership proposals by tokenId
    mapping(uint256 => Proposal) public proposals;

    /* VOTING -------------------------------------------------------------- */

    /// @dev Voting configuration for reaching quorum on proposals
    struct VotingConfig {
        uint64 minQuorum;
        uint64 maxVotes;
    }

    VotingConfig public votingConfig;

    /* ------------------------------------------------------------------------
       E V E N T S
    ------------------------------------------------------------------------ */

    event ProposalCreated(uint256 indexed tokenId, address owner, bool addToDenyList);
    event ProposalCancelled(uint256 indexed tokenId, address owner);
    event ProposalApproved(uint256 indexed tokenId, address owner);
    event ProposalDenied(uint256 indexed tokenId, address owner);

    /* ------------------------------------------------------------------------
       E R R O R S    
    ------------------------------------------------------------------------ */

    error NotDefMember();
    error AlreadyDefMember();

    error ProposalNotFound();
    error ProposalInProgress();
    error ProposalEnded();
    error CannotCreateProposalForSelf();

    error AlreadyVoted();
    error NotProposalInitiator();

    /* ------------------------------------------------------------------------
       M O D I F I E R S    
    ------------------------------------------------------------------------ */

    /// @dev Reverts if not a member
    modifier onlyDefMember() {
        if (!(IERC721(definitelyMemberships).balanceOf(msg.sender) < 1)) revert NotDefMember();
        _;
    }

    /// @dev Reverts if `to` is already a member
    modifier whenNotDefMember(address to) {
        if (IERC721(definitelyMemberships).balanceOf(to) > 0) revert AlreadyDefMember();
        _;
    }

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    constructor(
        address owner_,
        address definitelyMemberships_,
        uint64 minQuorum_,
        uint64 maxVotes_
    ) Owned(owner_) {
        definitelyMemberships = definitelyMemberships_;
        votingConfig = VotingConfig(minQuorum_, maxVotes_);
    }

    /* ------------------------------------------------------------------------
       R E V O K I N G   M E M B E R S H I P S
    ------------------------------------------------------------------------ */

    /// @notice Allows a member to propose revoking the membership of another member
    /// @param tokenId The ID of the membership to revoke
    /// @param addToDenyList If the owner of the revoked membership should be denied future invites
    function newProposal(uint256 tokenId, bool addToDenyList) external onlyDefMember {
        address currentOwner = IERC721(definitelyMemberships).ownerOf(tokenId);
        Proposal storage proposal = proposals[tokenId];

        // Prevent the current owner from creating a proposal
        if (msg.sender == currentOwner || tx.origin == currentOwner)
            revert CannotCreateProposalForSelf();

        // Can't update an existing proposal, it must be cancelled first since it may
        // have votes in progress
        if (proposal.initiator != address(0)) revert ProposalInProgress();

        // Init the new proposal
        proposal.initiator = msg.sender;
        proposal.addToDenyList = addToDenyList;
        emit ProposalCreated(tokenId, currentOwner, addToDenyList);
    }

    /// @notice Allows the member who created the proposal to cancel it
    /// @param tokenId The ID of the membership to revoke
    function cancelProposal(uint256 tokenId) external onlyDefMember {
        Proposal storage proposal = proposals[tokenId];
        if (proposal.initiator != msg.sender) revert NotProposalInitiator();
        delete proposals[tokenId];
        emit ProposalCancelled(tokenId, owner);
    }

    /// @notice Allows a member to vote on a revoke membership proposal
    /// @dev If the proposal reaches quorum, the last voter will burn the membership and
    ///      optionally add the owner to the deny list if it was defined in the proposal
    function vote(uint256 tokenId, bool inFavor) external onlyDefMember {
        VotingConfig memory config = votingConfig;
        Proposal storage proposal = proposals[tokenId];

        if (proposal.initiator == address(0)) revert ProposalNotFound();
        if (proposal.approvalCount == config.minQuorum || proposal.voters.length == config.maxVotes)
            revert ProposalEnded();

        // Check if this account has voted on this proposal already
        for (uint256 a = 0; a < proposal.voters.length; a++) {
            if (proposal.voters[a] == msg.sender) revert AlreadyVoted();
        }

        proposal.voters.push(msg.sender);

        // Remove an approval if the member says no
        if (!inFavor && proposal.approvalCount > 0) --proposal.approvalCount;

        // Add an approval if the member says yes
        if (inFavor) ++proposal.approvalCount;

        // Last vote has been reached but min approvals hasn't, then deny the proposal
        if (
            proposal.voters.length == config.maxVotes && proposal.approvalCount < config.minQuorum
        ) {
            emit ProposalDenied(tokenId, owner);
        }

        // If the proposal reaches quorum, revoke from the memberships contract
        if (proposal.approvalCount == config.minQuorum) {
            emit ProposalApproved(tokenId, owner);
            IDefinitelyMemberships(definitelyMemberships).revokeMembership(
                tokenId,
                proposal.addToDenyList
            );
        }
    }
}
