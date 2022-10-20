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
import "openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "./interfaces/IDefinitelyMemberships.sol";

/**
 * @title Definitely Claimable
 * @author DEF DAO
 * @notice A membership issuing contract that uses EIP-712 signatures to allow membership claiming
 */
contract DefinitelyClaimable is EIP712, Auth {
    /* ------------------------------------------------------------------------
       S T O R A G E    
    ------------------------------------------------------------------------ */

    /// @notice The main membership contract
    address public memberships;

    /// @dev EIP-712 signing domain
    string public constant SIGNING_DOMAIN = "DEFDAOMemberships";

    /// @dev EIP-712 signature version
    string public constant SIGNATURE_VERSION = "1";

    /// @dev EIP-712 signed data type hash for claiming a membership
    bytes32 public constant CLAIM_DROP_TYPEHASH =
        keccak256("ClaimMembership(address account,uint256 nonce)");

    /// @dev EIP-712 signed data struct for claiming a membership
    struct ClaimMembership {
        address account;
        uint256 nonce;
        bytes signature;
    }

    /// @dev Approved signer public addresses
    mapping(address => bool) public approvedSigners;

    /// @dev Nonce management to avoid signature replay attacks
    mapping(address => uint256) public nonces;

    /* ------------------------------------------------------------------------
       E V E N T S    
    ------------------------------------------------------------------------ */

    /// @dev Whenever a membership is claimed for an existing DEF member
    event MembershipClaimed(address indexed member);

    /// @dev Emitted when a new signer is added to this contract
    event SignerAdded(address indexed signer);

    /// @dev Emitted when an existing signer is removed from this contract
    event SignerRemoved(address indexed signer);

    /* ------------------------------------------------------------------------
       E R R O R S    
    ------------------------------------------------------------------------ */

    error InvalidSignature();

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    /**
     * @param owner_ Contract owner address
     * @param memberships_ The main membership contract
     * @param initialSigner_ An initial EIP-712 signing address
     */
    constructor(
        address owner_,
        address memberships_,
        address initialSigner_
    ) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) Auth(owner_, owner_) {
        memberships = memberships_;
        approvedSigners[initialSigner_] = true;
        emit SignerAdded(initialSigner_);
    }

    /* ------------------------------------------------------------------------
       C L A I M I N G
    ------------------------------------------------------------------------ */

    /**
     * @notice Allows someone to claim a DEF membership with a valid signature
     * @param signature A valid EIP-712 signature
     */
    function claimMembership(bytes calldata signature) external {
        // Reconstruct the signed data on-chain
        ClaimMembership memory data = ClaimMembership({
            account: msg.sender,
            nonce: nonces[msg.sender],
            signature: signature
        });

        // Hash the data for verification
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(CLAIM_DROP_TYPEHASH, data.account, nonces[data.account]++))
        );

        // Verifiy signature is ok
        address addr = ECDSA.recover(digest, data.signature);
        if (!approvedSigners[addr] || addr == address(0)) revert InvalidSignature();

        // Claim the membership
        IDefinitelyMemberships(memberships).issueMembership(msg.sender);
        emit MembershipClaimed(msg.sender);
    }

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice Admin function to add a new EIP-712 signer address
     * @dev Emits the SignerAdded event
     *
     * @param signer The address of the new signer
     */
    function addSigner(address signer) external onlyOwnerOrAdmin {
        approvedSigners[signer] = true;
        emit SignerAdded(signer);
    }

    /**
     * @notice Admin function to remove an existing EIP-712 signer address
     * @dev Emits the SignerRemoved event
     *
     * @param signer The address of the signer to remove
     */
    function removeSigner(address signer) external onlyOwnerOrAdmin {
        approvedSigners[signer] = false;
        emit SignerRemoved(signer);
    }
}
