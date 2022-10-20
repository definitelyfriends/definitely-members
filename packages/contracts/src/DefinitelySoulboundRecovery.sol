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
pragma solidity ^0.8.17;

import "./lib/Auth.sol";
import "./interfaces/IDefinitelyMemberships.sol";
import "openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title Definitely Soulbound Recovery
 * @author DEF DAO
 * @notice A contract to socially recover a membership based on a simple voting mechanism.
 */
contract DefinitelySoulboundRecovery is Auth {
    /* ------------------------------------------------------------------------
       S T O R A G E
    ------------------------------------------------------------------------ */

    /// @notice The main membership contract
    address public memberships;

    /* PROPOSALS ----------------------------------------------------------- */

    /// @dev Allows someone propose a transfer to a different wallet
    struct Proposal {
        uint256 id;
        uint8 approvalCount;
        address[] voters;
    }

    /// @notice Keeps track of transfer membership proposals by token id
    mapping(address => Proposal) public proposals;

    /* VOTING -------------------------------------------------------------- */

    /// @dev Voting configuration for reaching quorum on proposals
    struct VotingConfig {
        uint64 minQuorum;
        uint64 maxVotes;
    }

    /// @notice The voting configuration for this contract
    VotingConfig public votingConfig;

    /* ------------------------------------------------------------------------
       E V E N T S
    ------------------------------------------------------------------------ */

    event ProposalCreated(uint256 indexed id, address indexed to);
    event ProposalCancelled(uint256 indexed id, address indexed to);
    event ProposalApproved(uint256 indexed id, address indexed to);
    event ProposalDenied(uint256 indexed id, address indexed to);

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

    /// @dev Reverts if `msg.sender` is not a member
    modifier onlyDefMember() {
        if (!(IERC721(memberships).balanceOf(msg.sender) < 1)) revert NotDefMember();
        _;
    }

    /// @dev Reverts if `to` is already a member
    modifier whenNotDefMember(address to) {
        if (IERC721(memberships).balanceOf(to) > 0) revert AlreadyDefMember();
        _;
    }

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    /**
     * @param owner_ Contract owner address
     * @param memberships_ The main membership contract
     * @param minQuorum_ The min number of votes to approve a proposal
     * @param maxVotes_ The max number of votes a proposal can have
     */
    constructor(
        address owner_,
        address memberships_,
        uint64 minQuorum_,
        uint64 maxVotes_
    ) Auth(owner_, owner_) {
        memberships = memberships_;
        votingConfig = VotingConfig(minQuorum_, maxVotes_);
    }

    function setVotingConfig(uint64 minQuorum_, uint64 maxVotes_) external onlyOwner {
        votingConfig = VotingConfig(minQuorum_, maxVotes_);
    }

    /* ------------------------------------------------------------------------
       S O U L B O U N D   R E C O V E R Y
    ------------------------------------------------------------------------ */

    /**
     * @notice Allows someone to propose a transfer of a membership token to another address
     * @dev If a member's wallet is compromised, they can propose a transfer of their
     * membership NFT to a new wallet. Once a proposal is approved, the new wallet can call
     * `recoverMembership` to move their NFT.
     *
     * There can only be one proposal for a new address at any given time. If a new
     * proposal is submitted, any existing proposal will be overwritten. Only allows
     * non members to create proposals.
     */
    function newProposal(uint256 id) external whenNotDefMember(msg.sender) {
        Proposal storage proposal = proposals[msg.sender];

        // If overwriting an existing proposal, delete it and emit a cancel event
        if (proposal.id != 0 && proposal.id != id) {
            proposal.approvalCount = 0;
            delete proposal.voters;
            emit ProposalCancelled(id, msg.sender);
        }

        // Init the new proposal
        proposal.id = id;
        emit ProposalCreated(id, msg.sender);
    }

    /**
     * @notice Allows a member to vote on a transfer membership proposal
     * @dev If the proposal reaches quorum, it "unlocks" the ability for the new owner
     * to call `recoverMembership` and get their NFT transferred.
     *
     * Reverts if:
     *  - the proposal doesn't exist
     *  - the proposal has ended
     *  - `msg.sender` has already voted
     *
     * @param newOwner The new owner that created the proposal
     * @param inFavor Whether the caller is in favor of the proposal or not
     */
    function vote(address newOwner, bool inFavor) external onlyDefMember {
        VotingConfig memory config = votingConfig;
        Proposal storage proposal = proposals[newOwner];

        if (proposal.id == 0) revert ProposalNotFound();
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
            emit ProposalDenied(proposal.id, newOwner);
        }

        // If quorum has been reached, emit an event for notifications
        if (proposal.approvalCount == config.minQuorum) {
            emit ProposalApproved(proposal.id, newOwner);
        }
    }

    /**
     * @notice Recovers a membership token once a transfer proposal has been approved
     * @dev If the proposal is approved, the membership NFT will be transferred to the caller
     *
     * Reverts if:
     *  - the proposal doesn't exist
     *  - the proposal doesn't have enough votes to approve
     *
     * @param id The token id of the NFT to transfer
     */
    function recoverMembership(uint256 id) external {
        // Get the propsal for the person receiveing the token
        Proposal storage proposal = proposals[msg.sender];

        // Check if it can be transferred
        if (proposal.approvalCount < votingConfig.minQuorum || proposal.id != id) {
            revert NotAllowed();
        }

        // Call `transferMembership` on the memberships contract to transfer to msg.sender
        IDefinitelyMemberships(memberships).transferMembership(id, msg.sender);
    }
}
