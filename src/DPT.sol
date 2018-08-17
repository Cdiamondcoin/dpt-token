pragma solidity ^0.4.23;

import "ds-token/token.sol";

/**
 * @title DPT
 * @dev DPT coin.
 */
contract DPT is DSToken {
    string public constant name = "DPT";
    bytes32 public constant symbol = "DPT";
    uint8 public constant decimals = 18 ;

    /**
    * @dev Constructor that gives msg.sender all of existing tokens.
    */
    constructor() DSToken(symbol) public {
        uint totalSupply_ = mul(10 ** 7, (10 ** uint(decimals)));
        super.mint(totalSupply_);
        transfer(owner, totalSupply_);
    }

    /**
    * @dev override mint() function in DSToken so that no token can be minted only once in the constructor()
    */
    function mint(uint) public {
        revert("No minting possible.");
    }
}
