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
import "@openzeppelin/contracts/utils/Strings.sol";
import "@def/Base64.sol";
import "./interfaces/IDefinitelyMetadata.sol";

/// @title Definitely Metadata
/// @author DEF DAO
/// @notice The default metadata contract for DEF DAO membership tokens. On-chain metadata
///         with off-chain image URI that's updateable by the contract owner.
contract DefinitelyMetadata is IDefinitelyMetadata, Owned {
    using Strings for uint256;

    string public imageURI;
    string public description;

    constructor(address owner, string memory imageURI_) Owned(owner) {
        imageURI = imageURI_;
        description = "[DEF DAO](https://www.defdao.xyz/) membership token for people tinkering on the edge of the internet.";
    }

    function setImageURI(string memory imageURI_) external onlyOwner {
        imageURI = imageURI_;
    }

    function setDescription(string memory description_) external onlyOwner {
        description = description_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory json = Base64.encode(
            bytes(
                string.concat(
                    '{"name":"DEF Membership #',
                    tokenId.toString(),
                    '","description":"',
                    description,
                    '","image":"',
                    imageURI,
                    '","attributes":[]}'
                )
            )
        );

        return string.concat("data:application/json;base64,", json);
    }
}
