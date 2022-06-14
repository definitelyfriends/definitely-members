//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

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

import "@rari-capital/solmate/src/auth/Owned.sol";
import "@rari-capital/solmate/src/tokens/ERC721.sol";

import {IDefinitelyMemberships} from "./interfaces/IDefinitelyMemberships.sol";
import {IDefinitelyMetadata} from "./interfaces/IDefinitelyMetadata.sol";

/// @title Definitely Memberships
/// @author DEF DAO
/// @notice A membership token for DEF DAO in the form of an ERC721.
///
///         Features:
///           - Approved contracts for issuing memberships. This allows different issuing
///             mechanisms e.g. invites, props, funding etc.
///           - "Soulbound" tokens with social recovery in the form of transfer proposals.
///             Other members can approve proposals to transfer a certain token to a new address.
///           - Revoking proposals to remove members if it's ever needed.
///           - Separate upgradable metadata contract.
///           - Per token metadata overriding
///
contract DefinitelyMemberships is IDefinitelyMemberships, ERC721, Owned {
    /* ------------------------------------------------------------------------
       S T O R A G E
    ------------------------------------------------------------------------ */

    /* ERC-721 ------------------------------------------------------------- */

    /// @dev Tracks ERC-721 token ids
    uint256 public nextMembershipId = 1;

    /* ISSUING MEMBERSHIPS ------------------------------------------------- */

    /// @dev Contracts that are allowed to issue memberships
    mapping(address => bool) public allowedIssuingContracts;

    /// @dev Prevents an address from becoming an owner of this token
    mapping(address => bool) private _denyList;

    /* TRANSFERS ----------------------------------------------------------- */

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

    /* METADATA ------------------------------------------------------------ */

    /// @dev A fallback metadata address for all tokens that don't specify an override
    IDefinitelyMetadata public defaultMetadata;

    /// @dev Allows a specific token ID to use it's own metadata address
    mapping(uint256 => IDefinitelyMetadata) public tokenMetadataOverrideAddress;

    /* ------------------------------------------------------------------------
       E V E N T S
    ------------------------------------------------------------------------ */

    /* ISSUING MEMBERSHIPS ------------------------------------------------- */

    event IssuingContractAdded(address indexed contractAddress);
    event IssuingContractRevoked(address indexed contractAddress);

    /* TRANSFERS ----------------------------------------------------------- */

    event TransferMembershipProposalCreated(uint256 indexed tokenId, address owner, address to);
    event TransferMembershipProposalCancelled(uint256 indexed tokenId, address owner, address to);
    event TransferMembershipProposalApproved(uint256 indexed tokenId, address owner, address to);
    event TransferMembershipProposalDenied(uint256 indexed tokenId, address owner, address to);

    /* REVOKING ------------------------------------------------------------ */

    event RevokeMembershipProposalCreated(
        uint256 indexed tokenId,
        address owner,
        bool addToDenyList
    );
    event RevokeMembershipProposalCancelled(uint256 indexed tokenId, address owner);
    event RevokeMembershipProposalApproved(uint256 indexed tokenId, address owner);
    event RevokeMembershipProposalDenied(uint256 indexed tokenId, address owner);

    /* METADATA ------------------------------------------------------------ */

    event DefaultMetadataUpdated(address indexed metadata);
    event MetadataOverridden(uint256 indexed tokenId, address metadata);
    event MetadataResetToDefault(uint256 indexed tokenId);

    /* ------------------------------------------------------------------------
       E R R O R S
    ------------------------------------------------------------------------ */

    error NotAuthorizedToIssueMembership();
    error NotDefMember();
    error AlreadyDefMember();
    error OnDenyList();

    error TransferNotAllowed();
    error TransferMembershipProposalNotFound();
    error TransferMembershipProposalEnded();

    error RevokeMembershipProposalNotFound();
    error RevokeMembershipProposalInProgress();
    error RevokeMembershipProposalEnded();

    error AlreadyVoted();
    error NotProposalInitiator();

    error NotOwnerOfToken();

    /* ------------------------------------------------------------------------
       M O D I F I E R S
    ------------------------------------------------------------------------ */

    /// @dev Reverts if not a member
    modifier onlyDefMember() {
        if (_balanceOf[msg.sender] < 1) revert NotDefMember();
        _;
    }

    /// @dev Reverts if not an allowed minting contract
    modifier onlyIssuingContract() {
        if (!allowedIssuingContracts[msg.sender]) revert NotAuthorizedToIssueMembership();
        _;
    }

    /// @dev Reverts if `to` is already a member
    modifier whenNotDefMember(address to) {
        if (_balanceOf[to] > 0) revert AlreadyDefMember();
        _;
    }

    /// @dev Reverts if `to` is on the deny list
    modifier whenNotOnDenyList(address to) {
        if (_denyList[to]) revert OnDenyList();
        _;
    }

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    constructor(
        address owner_,
        IDefinitelyMetadata defaultMetadata_,
        uint64 minTransferMembershipQuorum_,
        uint64 maxTransferMembershipVotes_,
        uint64 minRevokeMembershipQuorum_,
        uint64 maxRevokeMembershipVotes_
    ) ERC721("DEF", "Definitely Membership") Owned(owner_) {
        defaultMetadata = defaultMetadata_;

        votingConfig = VotingConfig({
            minTransferMembershipQuorum: minTransferMembershipQuorum_,
            maxTransferMembershipVotes: maxTransferMembershipVotes_,
            minRevokeMembershipQuorum: minRevokeMembershipQuorum_,
            maxRevokeMembershipVotes: maxRevokeMembershipVotes_
        });
    }

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    /// @notice Adds a new membership issuing contract
    /// @dev The new contract will be able to mint membership tokens to people who aren't already
    ///      members, and who aren't on the deny list. There are no other restrictions so the
    ///      issuing contract must implement additional checks if necessary
    function addIssuingContract(address issuingContract) external onlyOwner {
        allowedIssuingContracts[issuingContract] = true;
        emit IssuingContractAdded(issuingContract);
    }

    /// @notice Revokes an existing membership issuing contract
    /// @dev This will prevent the contract from calling `issueMembership`
    function revokeIssuingContract(address issuingContract) external onlyOwner {
        allowedIssuingContracts[issuingContract] = false;
        emit IssuingContractRevoked(issuingContract);
    }

    /// @notice Updates the fallback metadata used for all tokens that haven't set an override
    function setDefaultMetadata(IDefinitelyMetadata defaultMetadata_) external onlyOwner {
        defaultMetadata = defaultMetadata_;
        emit DefaultMetadataUpdated(address(defaultMetadata_));
    }

    /* ------------------------------------------------------------------------
       M E M B E R S H I P   M I N T I N G
    ------------------------------------------------------------------------ */

    /// @notice Allows another contract to issue a membership token to someone
    /// @dev Reverts if this wasn't called from an approved issuing contract, if `to` is already
    ///      a member or they're on the deny list.
    function issueMembership(address to)
        external
        override
        onlyIssuingContract
        whenNotDefMember(to)
        whenNotOnDenyList(to)
    {
        _mint(to, nextMembershipId);
        ++nextMembershipId;
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
    /// @dev There can only be one transfer proposal for a new address at any given time. If a new
    ///      proposal is submitted, any existing proposal will be overwritten.
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
    ///      new address can transfer ownership, but only if the proposal reaches quorum.
    /// TODO: Should the last vote just automatically update the owner and emit a transfer event?
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

        // If quorum has been reached, approve the proposal, and the new owner to transfer
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
                _denyList[_ownerOf[tokenId]] = true;
            }
            _burn(tokenId);
        }
    }

    /* ------------------------------------------------------------------------
       M E T A D A T A
    ------------------------------------------------------------------------ */

    /// @notice Allows a token holder to set a new metadata address for tokenURI customization
    /// @param tokenId The token to override metadata for
    /// @param metadata The new metadata contract address for this token
    function overrideMetadataForToken(uint256 tokenId, IDefinitelyMetadata metadata) external {
        if (ownerOf(tokenId) != msg.sender) revert NotOwnerOfToken();
        tokenMetadataOverrideAddress[tokenId] = metadata;
    }

    /// @notice Allows a token holder to use the default metadata address for their token
    /// @param tokenId The token that should use the default metadata contract
    function resetMetadataForToken(uint256 tokenId) external {
        delete tokenMetadataOverrideAddress[tokenId];
    }

    /* ------------------------------------------------------------------------
       P U B L I C   G E T T E R S
    ------------------------------------------------------------------------ */

    /// @notice Checks if an account is part of DEF with a simple balance check
    function isDefMember(address account) external view returns (bool) {
        return _balanceOf[account] > 0;
    }

    /// @notice Checks if an account is on the DEF deny list. If they are, they will not be
    ///         allowed to become a member in the future.
    function isOnDenyList(address account) external view returns (bool) {
        return _denyList[account];
    }

    /* ------------------------------------------------------------------------
       E R C - 7 2 1
    ------------------------------------------------------------------------ */

    /// @notice Burn your membership token. Note, you will need to be invited again
    ///         if you want to re-join DEF later.
    function burn(uint256 tokenId) external {
        if (_ownerOf[tokenId] != msg.sender) revert NotOwnerOfToken();
        _burn(tokenId);
    }

    /// @dev If the token has a metadata override address, render from that, else use the default
    ///      metadata address as a fallback.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (tokenMetadataOverrideAddress[tokenId] != IDefinitelyMetadata(address(0))) {
            return tokenMetadataOverrideAddress[tokenId].tokenURI(tokenId);
        } else {
            return defaultMetadata.tokenURI(tokenId);
        }
    }
}
