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
import {IDefinitelyMetadata} from "./interfaces/IDefinitelyMetadata.sol";

/// @title Definitely Metadata
/// @author DEF DAO
/// @notice The default metadata contract for DEF DAO membership tokens, a simple baseURI style
///         implementation that allows the owner to update the baseURI.
contract DefinitelyMetadata is IDefinitelyMetadata, Owned {
    using Strings for uint256;

    string public baseURI;

    constructor(address owner, string memory baseURI_) Owned(owner) {
        baseURI = baseURI_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString()) : "";
    }
}
