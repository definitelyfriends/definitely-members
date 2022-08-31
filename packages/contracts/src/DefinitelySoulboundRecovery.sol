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

/// @title Definitely Soulbound Recovery
/// @author DEF DAO
/// @notice A contract to socially recover a membership based on a simple voting mechanism
contract DefinitelySoulboundRecovery is Owned {
    /* ------------------------------------------------------------------------
       S T O R A G E
    ------------------------------------------------------------------------ */

    /// @dev The main membership contract that issues NFTs
    address public definitelyMemberships;

    /* PROPOSALS ----------------------------------------------------------- */

    /// @dev Allows someone propose a transfer to a different wallet
    struct Proposal {
        uint256 tokenId;
        uint8 approvalCount;
        address[] voters;
    }

    /// @dev Keeps track of proposals by new wallet address
    mapping(address => Proposal) public proposals;

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

    event ProposalCreated(uint256 indexed tokenId, address owner, address to);
    event ProposalCancelled(uint256 indexed tokenId, address owner, address to);
    event ProposalApproved(uint256 indexed tokenId, address owner, address to);
    event ProposalDenied(uint256 indexed tokenId, address owner, address to);

    /* ------------------------------------------------------------------------
       E R R O R S    
    ------------------------------------------------------------------------ */

    error NotDefMember();
    error AlreadyDefMember();

    error ProposalNotFound();
    error ProposalEnded();
    error NotAllowed();

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
       S O U L B O U N D   R E C O V E R Y
    ------------------------------------------------------------------------ */

    /// @notice If a member's wallet is compromised, they can propose a transfer
    ///         of their membership NFT to a new wallet. Once a proposal is approved,
    ///         the new wallet can call `recoverMembership` to move their NFT.
    /// @dev There can only be one proposal for a new address at any given time. If a new
    ///      proposal is submitted, any existing proposal will be overwritten. Only allows
    ///      non members to create proposals.
    function newProposal(uint256 tokenId) external whenNotDefMember(msg.sender) {
        address currentOwner = IERC721(definitelyMemberships).ownerOf(tokenId);
        Proposal storage proposal = proposals[msg.sender];

        // If overwriting an existing proposal, delete it and emit a cancel event
        if (proposal.tokenId != 0 && proposal.tokenId != tokenId) {
            proposal.approvalCount = 0;
            delete proposal.voters;
            emit ProposalCancelled(tokenId, currentOwner, msg.sender);
        }

        // Init the new proposal
        proposal.tokenId = tokenId;
        emit ProposalCreated(tokenId, currentOwner, msg.sender);
    }

    /// @notice Allows a DEF member to vote for or against a recovery proposal
    /// @param newOwner The new owner that created the proposal
    /// @param inFavor Whether the caller is in favor of the proposal or not
    function vote(address newOwner, bool inFavor) external onlyDefMember {
        VotingConfig memory config = votingConfig;
        Proposal storage proposal = proposals[newOwner];

        if (proposal.tokenId == 0) revert ProposalNotFound();
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

        // Last vote has been reached but quorum hasn't, then deny the proposal
        if (
            proposal.voters.length == config.maxVotes && proposal.approvalCount < config.minQuorum
        ) {
            emit ProposalDenied(proposal.tokenId, owner, newOwner);
        }

        // If quorum has been reached, emit an event for notifications
        if (proposal.approvalCount == config.minQuorum) {
            emit ProposalApproved(proposal.tokenId, owner, newOwner);
        }
    }

    /// @notice Recovers a membership token once a social recovery proposal has reached quorum
    /// @param tokenId The token id to transfer
    function recoverMembership(uint256 tokenId) external {
        // Get the propsal for the person receiveing the token
        Proposal storage proposal = proposals[msg.sender];

        // Don't recover if...
        //   1. there's not enough approvals
        //   2. there's no proposal for this tokenId
        if (proposal.approvalCount < votingConfig.minQuorum || proposal.tokenId != tokenId) {
            revert NotAllowed();
        }

        // Call `transferMembership` on the memberships contract to transfer to msg.sender
        IDefinitelyMemberships(definitelyMemberships).transferMembership(tokenId, msg.sender);
    }
}
