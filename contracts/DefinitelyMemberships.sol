//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import "@rari-capital/solmate/src/auth/Owned.sol";
import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract DefinitelyMemberships is ERC721, Owned {
    using Strings for uint256;
    using MerkleProof for bytes32[];

    /* ------------------------------------------------------------------------
                                   S T O R A G E    
    ------------------------------------------------------------------------ */

    /* ERC-721 ------------------------------------------------------------- */

    /// @dev Tracks ERC-721 token ids
    uint256 public nextMembershipId = 1;

    /// @dev Usual tokenURI metadata stuff
    string public baseURI;

    /* INVITES ------------------------------------------------------------- */

    /// @dev Uses a merkle proof for existing members prior to this contract
    bytes32 public existingMembersClaimRoot;

    /// @dev Allows a member to set an address that can be claimed later
    mapping(address => bool) public inviteAvailable;

    /// @dev Used to prevent spam invites
    uint256 public inviteCooldown;

    /// @dev Used as a cooldown check to make sure a malicious member can't spam invite
    mapping(address => uint256) public memberLastSentInvite;

    /* SOULBOUND ----------------------------------------------------------- */

    /// @dev Allows someone propose a transfer to a different wallet
    struct TransferProposal {
        uint256 tokenId;
        uint8 approvalCount;
        address[] voters;
    }

    /// @dev Mapping of a members new wallet to a proposal
    mapping(address => TransferProposal) public pendingTransferProposals;

    /// @dev Used to allow members to vote on transfer proposals
    uint256 public minTransferProposalApprovalCount;
    uint256 public maxTransferProposalVotesCount;

    /* ------------------------------------------------------------------------
                                    E V E N T S    
    ------------------------------------------------------------------------ */

    event TransferProposalCreated(uint256 tokenId, address owner, address to);
    event TransferProposalCancelled(uint256 tokenId, address owner, address to);
    event TransferProposalApproved(uint256 tokenId, address owner, address to);
    event TransferProposalDenied(uint256 tokenId, address owner, address to);

    /* ------------------------------------------------------------------------
                                    E R R O R S    
    ------------------------------------------------------------------------ */

    error AlreadyDefMember();
    error NotDefMember();
    error InviteOnCooldown();
    error NoInviteToClaim();
    error TransferNotAllowed();
    error NoTransferProposalFound();
    error TransferProposalEnded();
    error AlreadyVotedOnTransferProposal();

    /* ------------------------------------------------------------------------
                                 M O D I F I E R S    
    ------------------------------------------------------------------------ */

    /// @dev Only allow a membership holder to perform actions
    modifier onlyDefMember() {
        if (_balanceOf[msg.sender] < 1) revert NotDefMember();
        _;
    }

    /// @dev Prevents existing members getting more memberships
    modifier whenNotDefMember(address to) {
        if (_balanceOf[to] > 0) revert AlreadyDefMember();
        _;
    }

    /// @dev Checks when a member last sent an invite and that it's after the cooldown
    modifier onlyWhenInviteNotOnCooldown() {
        if (memberLastSentInvite[msg.sender] + inviteCooldown < block.timestamp)
            revert InviteOnCooldown();
        _;
    }

    /* ------------------------------------------------------------------------
                           S E N D I N G   I N V I T E S    
    ------------------------------------------------------------------------ */

    /// @notice Send an invite to an address that can be claimed at a later time
    function sendClaimableInvite(address to) external onlyDefMember whenNotDefMember(to) {
        inviteAvailable[to] = true;
        _startInviteCooldown(msg.sender);
    }

    /// @notice Send an invite token directly to an address
    function sendImediateInvite(address to) external onlyDefMember whenNotDefMember(to) {
        _mint(to, nextMembershipId);
        ++nextMembershipId;
        _startInviteCooldown(msg.sender);
        _startInviteCooldown(to);
    }

    /* ------------------------------------------------------------------------
                          C L A I M I N G   I N V I T E S
    ------------------------------------------------------------------------ */

    /// @notice Allows someone to claim their invite if they have one available
    /// @dev Reverts if they're already a member, or there's no invite to claim
    function claimInvite() external whenNotDefMember(msg.sender) {
        if (inviteAvailable[msg.sender]) revert NoInviteToClaim();
        // Mint the membership
        _mint(msg.sender, nextMembershipId);
        ++nextMembershipId;
        // Start an invite cooldown so a new member can't immediately invite someone else
        _startInviteCooldown(msg.sender);
        // We don't really need to remove the available invite, but it's nice to clean up
        inviteAvailable[msg.sender] = false;
    }

    // TODO: existingMemberClaim for existing discord folks using a merkle tree

    /* ------------------------------------------------------------------------
                                 S O U L B O U N D
    ------------------------------------------------------------------------ */

    /// @notice If a members wallet is compromised, they can propose a transfer
    ///         of their membership NFT to a new wallet. A proposal will require a
    ///         certain number of approvals before `transferFrom` can be used.
    function proposeTransfer(uint256 tokenId) external whenNotDefMember(msg.sender) {
        address currentOwner = _ownerOf[tokenId];
        TransferProposal storage proposal = pendingTransferProposals[msg.sender];

        // If overwriting an existing proposal, delete it and emit a cancel event
        if (proposal.tokenId != 0 && proposal.tokenId != tokenId) {
            proposal.approvalCount = 0;
            delete proposal.voters;
            emit TransferProposalCancelled(tokenId, currentOwner, msg.sender);
        }

        // Initialise the new proposal
        pendingTransferProposals[msg.sender].tokenId = tokenId;
        emit TransferProposalCreated(tokenId, currentOwner, msg.sender);
    }

    /// @notice Allows a DEF member to approve/deny a token transfer. The last voting
    ///         member will automatically set `getApproved` to the new address so the
    //          new address can transfer ownership.
    function approveTransferProposal(address newOwner, bool approved) external onlyDefMember {
        TransferProposal storage proposal = pendingTransferProposals[newOwner];

        if (proposal.tokenId == 0) revert NoTransferProposalFound();
        if (
            proposal.approvalCount == minTransferProposalApprovalCount ||
            proposal.voters.length == maxTransferProposalVotesCount
        ) revert TransferProposalEnded();

        // Check if this account has voted on this proposal already
        for (uint256 a = 0; a < proposal.voters.length; a++) {
            if (proposal.voters[a] == msg.sender) revert AlreadyVotedOnTransferProposal();
        }

        proposal.voters.push(msg.sender);

        // Remove an approval if the member says no
        if (proposal.approvalCount > 0 && !approved) --proposal.approvalCount;

        // Add an approval if the member says yes
        if (approved) ++proposal.approvalCount;

        // Last vote has been reached but min approvals hasn't, then deny the proposal
        if (
            proposal.voters.length == maxTransferProposalVotesCount &&
            proposal.approvalCount < minTransferProposalApprovalCount
        ) {
            emit TransferProposalDenied(proposal.tokenId, owner, newOwner);
        }

        if (proposal.approvalCount == minTransferProposalApprovalCount) {
            emit TransferProposalApproved(proposal.tokenId, owner, newOwner);
            getApproved[proposal.tokenId] = newOwner;
            emit Approval(owner, newOwner, proposal.tokenId);
        }
    }

    /// @dev Prevents transfers unless there's a certain amount of approvals from other DEF members.
    ///      When a proposal is approved, `getApproved` is set to the proposal maker to enable transfers.
    ///      Also prevents an account owning more than 1 token.
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        if (_balanceOf[to] > 0) revert AlreadyDefMember();

        TransferProposal storage proposal = pendingTransferProposals[to];

        // Don't allow transfers if...
        //   1. there's not enough approvals
        //   2. there's no proposal for this tokenId
        //   3. the proposal creator is not `to`
        if (
            proposal.approvalCount < minTransferProposalApprovalCount ||
            proposal.tokenId != id ||
            to != msg.sender
        ) {
            revert TransferNotAllowed();
        }

        // Remove the proposal on successful transfer
        delete pendingTransferProposals[to];

        super.transferFrom(from, to, id);
    }

    /* ------------------------------------------------------------------------
                    R E V O K I N G   M E M B E R S H I P S    
    ------------------------------------------------------------------------ */

    // TODO: Implement revoking voting

    /* ------------------------------------------------------------------------
                         H E L P E R S   &   U T I L S    
    ------------------------------------------------------------------------ */

    /// @dev Starts the invite cooldown for an address
    function _startInviteCooldown(address inviter) internal {
        memberLastSentInvite[inviter] = block.timestamp;
    }

    /* ------------------------------------------------------------------------
                                   E R C - 7 2 1    
    ------------------------------------------------------------------------ */

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, id.toString())) : "";
    }

    constructor(
        string memory baseURI_,
        uint256 inviteCooldown_,
        uint256 minTransferProposalApprovalCount_,
        uint256 maxTransferProposalVotesCount_
    ) ERC721("DEF", "Definitely Membership") Owned(msg.sender) {
        baseURI = baseURI_;
        inviteCooldown = inviteCooldown_;
        minTransferProposalApprovalCount = minTransferProposalApprovalCount_;
        maxTransferProposalVotesCount = maxTransferProposalVotesCount_;
    }
}
