//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

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

import "@solmate/auth/Owned.sol";
import "@solmate/tokens/ERC721.sol";

import {IDefinitelyMemberships} from "./interfaces/IDefinitelyMemberships.sol";
import {IDefinitelyMetadata} from "./interfaces/IDefinitelyMetadata.sol";

/// @title Definitely Memberships
/// @author DEF DAO
/// @notice A membership token for DEF DAO in the form of an ERC721.
///
///         Features:
///           - Soulbound tokens. This can be bypassed by a membership transfer contract to
///             allow for social recovery if necessary.
///           - Approved contracts for issuing memberships. This allows different issuing
///             mechanisms e.g. invites, props, funding etc. at the same time.
///           - A separate contract for revoking memberships and logic.
///           - A separate upgradable metadata contract.
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
    mapping(address => bool) public allowedMembershipIssuingContracts;

    /* REVOKING MEMBERSHIPS ------------------------------------------------ */

    /// @dev Contract that's allowed to revoke memberships
    address public allowedMembershipRevokingContract;

    /// @dev Prevents an address from becoming an owner of this token
    mapping(address => bool) private _denyList;

    /* TRANSFERRING MEMBERSHIPS -------------------------------------------- */

    /// @dev Contract that's allowed to transfer memberships in cases of access loss
    address public allowedMembershipTransferContract;

    /* METADATA ------------------------------------------------------------ */

    /// @dev A fallback metadata address for all tokens that don't specify an override
    IDefinitelyMetadata public defaultMetadata;

    /// @dev Allows a specific token ID to use it's own metadata address
    mapping(uint256 => IDefinitelyMetadata) public tokenMetadataOverrideAddress;

    /* ------------------------------------------------------------------------
       E V E N T S
    ------------------------------------------------------------------------ */

    /* ISSUING MEMBERSHIPS ------------------------------------------------- */

    event MembershipIssuingContractAdded(address indexed contractAddress);
    event MembershipIssuingContractRemoved(address indexed contractAddress);
    event MembershipIssued(uint256 indexed tokenId, address newOwner);

    /* REVOKING MEMBERSHIPS ------------------------------------------------ */

    event MembershipRevokingContractSet(address indexed contractAddress);
    event MembershipRevoked(uint256 indexed tokenId, address prevOwner);
    event AddedToDenyList(address indexed account);
    event RemovedFromDenyList(address indexed account);

    /* TRANSFERRING MEMBERSHIPS -------------------------------------------- */

    event MembershipTransferContractSet(address indexed contractAddress);

    /* METADATA ------------------------------------------------------------ */

    event DefaultMetadataUpdated(address indexed metadata);
    event MetadataOverridden(uint256 indexed tokenId, address metadata);
    event MetadataResetToDefault(uint256 indexed tokenId);

    /* ------------------------------------------------------------------------
       E R R O R S
    ------------------------------------------------------------------------ */

    error NotAuthorizedToIssueMembership();
    error NotAuthorizedToRevokeMembership();
    error NotAuthorizedToTransferMembership();

    error NotDefMember();
    error AlreadyDefMember();
    error NotOwnerOfToken();
    error OnDenyList();

    error CannotTransferToZeroAddress();

    /* ------------------------------------------------------------------------
       M O D I F I E R S
    ------------------------------------------------------------------------ */

    /// @dev Reverts if not a member
    modifier onlyDefMember() {
        if (_balanceOf[msg.sender] < 1) revert NotDefMember();
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

    /// @dev Reverts if not an allowed minting contract
    modifier onlyMembershipIssuingContract() {
        if (!allowedMembershipIssuingContracts[msg.sender]) revert NotAuthorizedToIssueMembership();
        _;
    }

    /// @dev Reverts if not the allowed membership revoking
    modifier onlyMembershipRevokingContract() {
        if (allowedMembershipRevokingContract != msg.sender)
            revert NotAuthorizedToRevokeMembership();
        _;
    }

    /// @dev Reverts if not the allowed membership transfer contract
    modifier onlyMembershipTransferContract() {
        if (allowedMembershipTransferContract != msg.sender)
            revert NotAuthorizedToTransferMembership();
        _;
    }

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    constructor(address owner_, IDefinitelyMetadata defaultMetadata_)
        ERC721("DEF", "Definitely Membership")
        Owned(owner_)
    {
        defaultMetadata = defaultMetadata_;
    }

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    /// @notice Adds a new membership issuing contract
    /// @dev The new contract will be able to mint membership tokens to people who aren't already
    ///      members, and who aren't on the deny list. There are no other restrictions so the
    ///      issuing contract must implement additional checks if necessary
    function addMembershipIssuingContract(address contractAddr) external onlyOwner {
        allowedMembershipIssuingContracts[contractAddr] = true;
        emit MembershipIssuingContractAdded(contractAddr);
    }

    /// @notice Revokes an existing membership issuing contract
    /// @dev This will prevent the contract from calling `issueMembership`
    function removeMembershipIssuingContract(address contractAddr) external onlyOwner {
        allowedMembershipIssuingContracts[contractAddr] = false;
        emit MembershipIssuingContractRemoved(contractAddr);
    }

    /// @notice Sets the membership revoking contract
    /// @dev The new contract will be able to burn tokens effectively revoking membership
    function setMembershipRevokingContract(address contractAddr) external onlyOwner {
        allowedMembershipRevokingContract = contractAddr;
        emit MembershipRevokingContractSet(contractAddr);
    }

    /// @notice Sets the membership transferring contract
    /// @dev The new contract will be able to bypass the soulbound mechanic and initiate a transfer
    function setMembershipTransferContract(address contractAddr) external onlyOwner {
        allowedMembershipTransferContract = contractAddr;
        emit MembershipTransferContractSet(contractAddr);
    }

    /// @notice Updates the fallback metadata used for all tokens that haven't set an override
    function setDefaultMetadata(IDefinitelyMetadata contractAddr) external onlyOwner {
        defaultMetadata = contractAddr;
        emit DefaultMetadataUpdated(address(contractAddr));
    }

    /* ------------------------------------------------------------------------
       I S S U I N G   M E M B E R S H I P S
    ------------------------------------------------------------------------ */

    /// @notice Allows another contract to issue a membership token to someone
    /// @dev Reverts if this wasn't called from an approved issuing contract, if `to` is already
    ///      a member or they're on the deny list.
    function issueMembership(address to)
        external
        override
        onlyMembershipIssuingContract
        whenNotDefMember(to)
        whenNotOnDenyList(to)
    {
        _mint(to, nextMembershipId);
        ++nextMembershipId;
    }

    /* ------------------------------------------------------------------------
       R E V O K I N G   M E M B E R S H I P S
    ------------------------------------------------------------------------ */

    /// @notice Revokes a membership by burning a token
    /// @dev Only callable by the membership revoking contract. This allows some level of
    ///      governance for when a membership should be revoked. Optionally adds the address
    ///      to the deny list so they cannot be issued a new membership in the future.
    /// @param tokenId The token id of the membership to revoke
    /// @param addToDenyList Whether to add the current owner to the deny list
    function revokeMembership(uint256 tokenId, bool addToDenyList)
        external
        onlyMembershipRevokingContract
    {
        address prevOwner = _ownerOf[tokenId];
        if (addToDenyList) _setDenyListStatus(prevOwner, true);
        _burn(tokenId);
        emit MembershipRevoked(tokenId, prevOwner);
    }

    /// @notice Adds an address to the deny list
    /// @dev Only callable by the membership revoking contract. This allows some level of
    ///      governance for when an address should be added to the deny list.
    /// @param account The account to add to the deny list
    function addAddressToDenyList(address account) public onlyMembershipRevokingContract {
        _setDenyListStatus(account, true);
    }

    /// @notice Removes an address from the deny list
    /// @dev Only callable by the membership revoking contract. This allows some level of
    ///      governance for when an address should be removed from the deny list.
    /// @param account The account to remove from the deny list
    function removeAddressFromDenyList(address account) external onlyMembershipRevokingContract {
        _setDenyListStatus(account, false);
    }

    /// @dev Internal function to manage deny list status and emit relevant events
    /// @param account The account to set the deny list status for
    /// @param isDenied Whether the account should be on the deny list or not
    function _setDenyListStatus(address account, bool isDenied) internal {
        if (isDenied) {
            _denyList[account] = true;
            emit AddedToDenyList(account);
        } else {
            _denyList[account] = false;
            emit RemovedFromDenyList(account);
        }
    }

    /* ------------------------------------------------------------------------
       T R A N S F E R R I N G   M E M B E R S H I P S
    ------------------------------------------------------------------------ */

    /// @notice Allows an account to bypass the soulbound mechanic and transfer a membership
    /// @dev Only callable by the membership transfer contract. This allows for some level of
    ///      governance around when to actually allow a membership transfer to happen.
    function transferMembership(uint256 tokenId, address to)
        external
        onlyMembershipTransferContract
    {
        if (to == address(0)) revert CannotTransferToZeroAddress();
        address from = _ownerOf[tokenId];

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;
            _balanceOf[to]++;
        }

        _ownerOf[tokenId] = to;
        delete getApproved[tokenId];
        emit Transfer(from, to, tokenId);
    }

    /* ------------------------------------------------------------------------
       S O U L B O U N D
    ------------------------------------------------------------------------ */

    /// @dev Prevents transfers of membership tokens. If a transfer is required, use the
    ///      approved membership transfer contract to create a proposal and `transferMembership`.
    function transferFrom(
        address,
        address,
        uint256
    ) public virtual override {
        revert NotAuthorizedToTransferMembership();
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
