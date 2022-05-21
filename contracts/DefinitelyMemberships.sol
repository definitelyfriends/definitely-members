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

    /// @dev Prevents an address from being invited
    mapping(address => bool) public denyList;

    /* SOULBOUND ----------------------------------------------------------- */

    /// @dev Allows someone propose a transfer to a different wallet
    struct TransferMembershipProposal {
        uint256 tokenId;
        uint8 approvalCount;
        address[] voters;
    }

    /// @dev Keeps track of transfer proposals by new wallet address
    mapping(address => TransferMembershipProposal) public transferMembershipProposals;

    /* REVOKING ------------------------------------------------------------ */

    /// @dev Allows a member to propose another membership be revoked
    struct RevokeMembershipProposal {
        address initiator;
        uint8 approvalCount;
        bool addToDenyList;
        address[] voters;
    }

    /// @dev Keeps track of revoke proposals by tokenId
    mapping(uint256 => RevokeMembershipProposal) public revokeMembershipProposals;

    /* VOTING -------------------------------------------------------------- */

    /// @dev Voting configuration for reaching quorum on proposals
    struct VotingConfig {
        uint64 minTransferMembershipQuorum;
        uint64 maxTransferMembershipVotes;
        uint64 minRevokeMembershipQuorum;
        uint64 maxRevokeMembershipVotes;
    }

    VotingConfig public votingConfig;

    /* ------------------------------------------------------------------------
                                    E V E N T S    
    ------------------------------------------------------------------------ */

    event TransferMembershipProposalCreated(uint256 tokenId, address owner, address to);
    event TransferMembershipProposalCancelled(uint256 tokenId, address owner, address to);
    event TransferMembershipProposalApproved(uint256 tokenId, address owner, address to);
    event TransferMembershipProposalDenied(uint256 tokenId, address owner, address to);

    event RevokeMembershipProposalCreated(uint256 tokenId, address owner, bool addToDenyList);
    event RevokeMembershipProposalCancelled(uint256 tokenId, address owner);
    event RevokeMembershipProposalApproved(uint256 tokenId, address owner);
    event RevokeMembershipProposalDenied(uint256 tokenId, address owner);

    /* ------------------------------------------------------------------------
                                    E R R O R S    
    ------------------------------------------------------------------------ */

    error NotDefMember();
    error AlreadyDefMember();

    error InviteOnCooldown();
    error NoInviteToClaim();
    error NotYourMembershipToken();
    error InvitedMemberOnDenyList();

    error TransferNotAllowed();
    error TransferMembershipProposalNotFound();
    error TransferMembershipProposalEnded();

    error RevokeMembershipProposalNotFound();
    error RevokeMembershipProposalEnded();
    error RevokeMembershipProposalInProgress();

    error AlreadyVoted();
    error NotProposalInitiator();

    /* ------------------------------------------------------------------------
                                 M O D I F I E R S    
    ------------------------------------------------------------------------ */

    /// @dev Reverts if not a member
    modifier onlyDefMember() {
        if (_balanceOf[msg.sender] < 1) revert NotDefMember();
        _;
    }

    /// @dev Reverts if the person being invited is already a member
    modifier whenNotDefMember(address to) {
        if (_balanceOf[to] > 0) revert AlreadyDefMember();
        _;
    }

    /// @dev Reverts if an invite is currently on cooldown
    modifier whenInviteNotOnCooldown() {
        if (memberLastSentInvite[msg.sender] + inviteCooldown < block.timestamp)
            revert InviteOnCooldown();
        _;
    }

    /// @dev Reverts if `to` is on the deny list
    modifier whenNotOnDenyList(address to) {
        if (denyList[to]) revert InvitedMemberOnDenyList();
        _;
    }

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */

    constructor(
        address owner_,
        string memory baseURI_,
        bytes32 existingMembersClaimRoot_,
        uint256 inviteCooldown_,
        uint64 minTransferMembershipQuorum_,
        uint64 maxTransferMembershipVotes_,
        uint64 minRevokeMembershipQuorum_,
        uint64 maxRevokeMembershipVotes_
    ) ERC721("DEF", "Definitely Membership") Owned(owner_) {
        baseURI = baseURI_;
        existingMembersClaimRoot = existingMembersClaimRoot_;
        inviteCooldown = inviteCooldown_;

        votingConfig = VotingConfig({
            minTransferMembershipQuorum: minTransferMembershipQuorum_,
            maxTransferMembershipVotes: maxTransferMembershipVotes_,
            minRevokeMembershipQuorum: minRevokeMembershipQuorum_,
            maxRevokeMembershipVotes: maxRevokeMembershipVotes_
        });
    }

    /* ------------------------------------------------------------------------
                           S E N D I N G   I N V I T E S    
    ------------------------------------------------------------------------ */

    /// @notice Send an invite to an address that can be claimed at a later time
    function sendClaimableInvite(address to)
        external
        onlyDefMember
        whenInviteNotOnCooldown
        whenNotDefMember(to)
        whenNotOnDenyList(to)
    {
        inviteAvailable[to] = true;
        _startInviteCooldown(msg.sender);
    }

    /// @notice Send an invite token directly to an address
    function sendImediateInvite(address to)
        external
        onlyDefMember
        whenInviteNotOnCooldown
        whenNotDefMember(to)
        whenNotOnDenyList(to)
    {
        _mintMembership(to);
        _startInviteCooldown(msg.sender);
    }

    /* ------------------------------------------------------------------------
                          C L A I M I N G   I N V I T E S
    ------------------------------------------------------------------------ */

    /// @notice Allows someone to claim their invite if they have one available
    /// @dev Reverts if they're already a member, or there's no invite to claim
    function claimInvite() external whenNotDefMember(msg.sender) whenNotOnDenyList(msg.sender) {
        if (inviteAvailable[msg.sender]) revert NoInviteToClaim();
        _mintMembership(msg.sender);

        // We don't really need to remove the available invite, but it's nice to clean up
        inviteAvailable[msg.sender] = false;
    }

    /// @notice Allows existing members (prior to this contract deploy) to claim their NFT
    /// @dev Requires the existing list of members to be set in a merkle root upon deploy
    /// @param proof A merkle proof containing eligible addresses
    function claimPriorMembership(bytes32[] memory proof)
        external
        whenNotDefMember(msg.sender)
        whenNotOnDenyList(msg.sender)
    {
        // Check the address and proof
        if (!proof.verify(existingMembersClaimRoot, keccak256(abi.encodePacked(msg.sender)))) {
            revert NoInviteToClaim();
        }
        _mintMembership(msg.sender);
    }

    /* ------------------------------------------------------------------------
                                 S O U L B O U N D
    ------------------------------------------------------------------------ */

    /// @dev Prevents transfers unless there's a certain amount of approvals from other DEF members.
    ///      When a transfer membership proposal is approved, `ERC721.{getApproved}` is set to the
    //       proposal maker to enable transfers.
    //       Also prevents an account owning more than 1 token by doing a balance check on `to`.
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        if (_balanceOf[to] > 0) revert AlreadyDefMember();

        // Get the propsal for the person receiveing the token
        TransferMembershipProposal storage proposal = transferMembershipProposals[to];

        // Don't allow transfers if...
        //   1. there's not enough approvals
        //   2. there's no proposal for this tokenId
        //   3. msg.sender is not the proposal creator
        if (
            proposal.approvalCount < votingConfig.minTransferMembershipQuorum ||
            proposal.tokenId != id ||
            to != msg.sender
        ) {
            revert TransferNotAllowed();
        }

        // Remove the proposal on successful transfer
        delete transferMembershipProposals[to];

        super.transferFrom(from, to, id);
    }

    /// @notice If a member's wallet is compromised, they can propose a transfer
    ///         of their membership NFT to a new wallet. Once a proposal is approved,
    ///         the new wallet can call `transferFrom` to move their NFT.
    function newTransferMembershipProposal(uint256 tokenId) external whenNotDefMember(msg.sender) {
        address currentOwner = _ownerOf[tokenId];
        TransferMembershipProposal storage proposal = transferMembershipProposals[msg.sender];

        // If overwriting an existing proposal, delete it and emit a cancel event
        if (proposal.tokenId != 0 && proposal.tokenId != tokenId) {
            proposal.approvalCount = 0;
            delete proposal.voters;
            emit TransferMembershipProposalCancelled(tokenId, currentOwner, msg.sender);
        }

        // Init the new proposal
        proposal.tokenId = tokenId;
        emit TransferMembershipProposalCreated(tokenId, currentOwner, msg.sender);
    }

    /// @notice Allows a DEF member to vote for or against a membership transfer proposal
    /// @dev The last voting member will automatically set `getApproved` to the new address so the
    //       new address can transfer ownership, but only if the proposal reaches quorum
    function voteOnTransferMembershipProposal(address newOwner, bool inFavor)
        external
        onlyDefMember
    {
        VotingConfig memory config = votingConfig;
        TransferMembershipProposal storage proposal = transferMembershipProposals[newOwner];

        if (proposal.tokenId == 0) revert TransferMembershipProposalNotFound();
        if (
            proposal.approvalCount == config.minTransferMembershipQuorum ||
            proposal.voters.length == config.maxTransferMembershipVotes
        ) revert TransferMembershipProposalEnded();

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
            proposal.voters.length == config.maxTransferMembershipVotes &&
            proposal.approvalCount < config.minTransferMembershipQuorum
        ) {
            emit TransferMembershipProposalDenied(proposal.tokenId, owner, newOwner);
        }

        // If quorum has been reached, approve the proposal
        if (proposal.approvalCount == config.minTransferMembershipQuorum) {
            emit TransferMembershipProposalApproved(proposal.tokenId, owner, newOwner);
            getApproved[proposal.tokenId] = newOwner;
            emit Approval(owner, newOwner, proposal.tokenId);
        }
    }

    /* ------------------------------------------------------------------------
                    R E V O K I N G   M E M B E R S H I P S    
    ------------------------------------------------------------------------ */

    /// @notice Allows a member to propose revoking the membership of another member
    /// @param tokenId The ID of the membership to revoke
    /// @param addToDenyList If the owner of the revoked membership should be denied future invites
    function newRevokeMembershipProposal(uint256 tokenId, bool addToDenyList)
        external
        onlyDefMember
    {
        address currentOwner = _ownerOf[tokenId];
        RevokeMembershipProposal storage proposal = revokeMembershipProposals[tokenId];

        // Can't update an existing proposal, it must be cancelled first otherwise
        // the member who is having their membership revoked could keep cancelling
        // proposals to avoid having their membership revoked
        if (proposal.initiator == address(0)) revert RevokeMembershipProposalInProgress();

        // Init the new proposal
        proposal.initiator = msg.sender;
        proposal.addToDenyList = addToDenyList;
        emit RevokeMembershipProposalCreated(tokenId, currentOwner, addToDenyList);
    }

    /// @notice Allows the member who created the proposal to cancel it
    /// @param tokenId The ID of the membership to revoke
    function cancelRevokeMembershipProposal(uint256 tokenId) external onlyDefMember {
        RevokeMembershipProposal storage proposal = revokeMembershipProposals[tokenId];
        if (proposal.initiator != msg.sender) revert NotProposalInitiator();
        delete revokeMembershipProposals[tokenId];
        emit RevokeMembershipProposalCancelled(tokenId, owner);
    }

    /// @notice Allows a member to vote on a revoke membership proposal
    /// @dev If the proposal reaches quorum, the last voter will burn the membership and
    ///      optionally add the owner to the deny list if it was defined in the proposal
    function voteOnRevokeMembershipProposal(uint256 tokenId, bool inFavor) external onlyDefMember {
        VotingConfig memory config = votingConfig;
        RevokeMembershipProposal storage proposal = revokeMembershipProposals[tokenId];

        if (proposal.initiator == address(0)) revert RevokeMembershipProposalNotFound();
        if (
            proposal.approvalCount == config.minRevokeMembershipQuorum ||
            proposal.voters.length == config.maxRevokeMembershipVotes
        ) revert RevokeMembershipProposalEnded();

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
            proposal.voters.length == config.maxRevokeMembershipVotes &&
            proposal.approvalCount < config.minRevokeMembershipQuorum
        ) {
            emit RevokeMembershipProposalDenied(tokenId, owner);
        }

        // If the proposal reaches quorum, burn the token and optionally add to deny list
        if (proposal.approvalCount == config.minRevokeMembershipQuorum) {
            emit RevokeMembershipProposalApproved(tokenId, owner);
            if (proposal.addToDenyList) {
                denyList[_ownerOf[tokenId]] = true;
            }
            _burn(tokenId);
        }
    }

    /* ------------------------------------------------------------------------
                         H E L P E R S   &   U T I L S    
    ------------------------------------------------------------------------ */

    /// @dev Starts the invite cooldown for an address
    function _startInviteCooldown(address inviter) internal {
        memberLastSentInvite[inviter] = block.timestamp;
    }

    function _mintMembership(address to) internal {
        _mint(to, nextMembershipId);
        ++nextMembershipId;
        _startInviteCooldown(to);
    }

    /* ------------------------------------------------------------------------
                                   E R C - 7 2 1    
    ------------------------------------------------------------------------ */

    /// @notice Burn your membership token. Note, you will need to be invited again
    ///         if you want to re-join DEF later.
    function burn(uint256 tokenId) external {
        if (_ownerOf[tokenId] != msg.sender) revert NotYourMembershipToken();
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return
            bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
}
