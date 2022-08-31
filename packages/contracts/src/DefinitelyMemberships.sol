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
import "@solmate/tokens/ERC721.sol";
import "./interfaces/IDefinitelyMemberships.sol";
import "./interfaces/IDefinitelyMetadata.sol";

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

    /// @dev Maps a token id to the block number it was issued at for "insight" score
    mapping(uint256 => uint256) private _memberSinceBlock;

    /* REVOKING MEMBERSHIPS ------------------------------------------------ */

    /// @dev Contracts that are allowed to revoke memberships
    mapping(address => bool) public allowedMembershipRevokingContracts;

    /// @dev Prevents an address from becoming an owner of this token
    mapping(address => bool) private _denyList;

    /* TRANSFERRING MEMBERSHIPS -------------------------------------------- */

    /// @dev Contracts that are allowed to transfer memberships in cases of access loss
    mapping(address => bool) public allowedMembershipTransferContracts;

    /* METADATA ------------------------------------------------------------ */

    /// @dev A fallback metadata address for all tokens that don't specify an override
    IDefinitelyMetadata private _defaultMetadata;

    /// @dev Allows a specific token ID to use it's own metadata address
    mapping(uint256 => IDefinitelyMetadata) public tokenMetadataOverrideAddress;

    /* ------------------------------------------------------------------------
       E V E N T S
    ------------------------------------------------------------------------ */

    /* INIT ---------------------------------------------------------------- */

    event DefinitelyShipping();

    /* ISSUING MEMBERSHIPS ------------------------------------------------- */

    event MembershipIssuingContractAdded(address indexed contractAddress);
    event MembershipIssuingContractRemoved(address indexed contractAddress);
    event MembershipIssued(uint256 indexed tokenId, address indexed newOwner);

    /* REVOKING MEMBERSHIPS ------------------------------------------------ */

    event MembershipRevokingContractAdded(address indexed contractAddress);
    event MembershipRevokingContractRemoved(address indexed contractAddress);
    event MembershipRevoked(uint256 indexed tokenId, address prevOwner);
    event AddedToDenyList(address indexed account);
    event RemovedFromDenyList(address indexed account);

    /* TRANSFERRING MEMBERSHIPS -------------------------------------------- */

    event MembershipTransferContractAdded(address indexed contractAddress);
    event MembershipTransferContractRemoved(address indexed contractAddress);

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
        if (!allowedMembershipIssuingContracts[msg.sender]) {
            revert NotAuthorizedToIssueMembership();
        }
        _;
    }

    /// @dev Reverts if not the allowed membership revoking
    modifier onlyMembershipRevokingContract() {
        if (!allowedMembershipRevokingContracts[msg.sender]) {
            revert NotAuthorizedToRevokeMembership();
        }
        _;
    }

    /// @dev Reverts if not the allowed membership transfer contract
    modifier onlyMembershipTransferContract() {
        if (!allowedMembershipTransferContracts[msg.sender]) {
            revert NotAuthorizedToTransferMembership();
        }
        _;
    }

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    constructor(address owner_) ERC721("DEF", "Definitely Membership") Owned(owner_) {
        emit DefinitelyShipping();
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
        _memberSinceBlock[nextMembershipId] = block.number;
        emit MembershipIssued(nextMembershipId, to);
        unchecked {
            ++nextMembershipId;
        }
    }

    /* ------------------------------------------------------------------------
       R E V O K I N G   M E M B E R S H I P S
    ------------------------------------------------------------------------ */

    /// @notice Revokes a membership by burning a token
    /// @dev Only callable by the membership revoking contract. This allows some level of
    ///      governance for when a membership should be revoked. Optionally adds the address
    ///      to the deny list so they cannot be issued a new membership in the future.
    /// @param id The token id of the membership to revoke
    /// @param addToDenyList Whether to add the current owner to the deny list
    function revokeMembership(uint256 id, bool addToDenyList)
        external
        onlyMembershipRevokingContract
    {
        address prevOwner = _ownerOf[id];
        if (addToDenyList) _setDenyListStatus(prevOwner, true);
        _burn(id);
        emit MembershipRevoked(id, prevOwner);
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
    /// @param id The token id of the membership being transferred
    /// @param to The new owner of the memerbship token
    function transferMembership(uint256 id, address to) external onlyMembershipTransferContract {
        if (to == address(0)) revert CannotTransferToZeroAddress();
        address from = _ownerOf[id];

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;
        delete getApproved[id];
        emit Transfer(from, to, id);
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
    function overrideMetadataForToken(uint256 tokenId, address metadata) external {
        if (ownerOf(tokenId) != msg.sender) revert NotOwnerOfToken();
        tokenMetadataOverrideAddress[tokenId] = IDefinitelyMetadata(metadata);
    }

    /// @notice Allows a token holder to use the default metadata address for their token
    /// @param tokenId The token that should use the default metadata contract
    function resetMetadataForToken(uint256 tokenId) external {
        delete tokenMetadataOverrideAddress[tokenId];
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
            return _defaultMetadata.tokenURI(tokenId);
        }
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

    /// @notice Removes an existing membership issuing contract
    /// @dev This will prevent the contract from calling `issueMembership`
    function removeMembershipIssuingContract(address contractAddr) external onlyOwner {
        allowedMembershipIssuingContracts[contractAddr] = false;
        emit MembershipIssuingContractRemoved(contractAddr);
    }

    /// @notice Adds a new membership revoking contract
    /// @dev The new contract will be able to burn tokens effectively revoking membership
    function addMembershipRevokingContract(address contractAddr) external onlyOwner {
        allowedMembershipRevokingContracts[contractAddr] = true;
        emit MembershipRevokingContractAdded(contractAddr);
    }

    /// @notice Removes an existing membership revoking contract
    /// @dev This will prevent the contract from calling `revokeMembership`
    function removeMembershipRevokingContract(address contractAddr) external onlyOwner {
        allowedMembershipRevokingContracts[contractAddr] = false;
        emit MembershipRevokingContractRemoved(contractAddr);
    }

    /// @notice Adds a new membership transfer contract
    /// @dev The new contract will be able to bypass the soulbound mechanic and initiate a transfer
    function addMembershipTransferContract(address contractAddr) external onlyOwner {
        allowedMembershipTransferContracts[contractAddr] = true;
        emit MembershipTransferContractAdded(contractAddr);
    }

    /// @notice Removes an existing membership transfer contract
    /// @dev This will prevent the contract from calling `transferMembership`
    function removeMembershipTransferContract(address contractAddr) external onlyOwner {
        allowedMembershipTransferContracts[contractAddr] = false;
        emit MembershipTransferContractRemoved(contractAddr);
    }

    /// @notice Updates the fallback metadata used for all tokens that haven't set an override
    function setDefaultMetadata(address contractAddr) external onlyOwner {
        _defaultMetadata = IDefinitelyMetadata(contractAddr);
        emit DefaultMetadataUpdated(contractAddr);
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

    /// @notice Returns the block number for when the token was issued
    function memberSinceBlock(uint256 tokenId) public view returns (uint256) {
        return _memberSinceBlock[tokenId];
    }

    /// @notice Gets the fallback metadata contract address. Metadata can be overridden on
    ///         a per token basis e.g. a member wants to change the image or title.
    function defaultMetadata() external view returns (address) {
        return address(_defaultMetadata);
    }
}
