pragma solidity ^0.4.23;

import "ds-math/math.sol";
import "ds-auth/auth.sol";
import "ds-token/token.sol";
import "ds-stop/stop.sol";

/**
 * @title DPT
 * @dev DPTICO contract.
 */
contract DPTICO is DSAuth, DSStop, DSMath {
    uint256 public rate = 1 ether;  //set exchange rate of 1 DPT/ETH

    DSToken _dpt;                   //DPT token contract

    /**
    * @dev Constructor that gives msg.sender all of existing tokens.
    */
    constructor(DSToken dpt) public {
         _dpt = dpt;
    }

    /**
    * @dev Fallback function is used to buy tokens.
    */
    function () external payable {
        buyTokens();
    }

    /**
    * @dev Low level token purchase function.
    */
    function buyTokens() public payable stoppable {
        uint tokens;
        require(msg.value != 0);
        tokens = wmul(rate, msg.value);
        address(owner).transfer(msg.value);
        _dpt.transferFrom(owner, msg.sender, tokens);
    }

    /**
    * @dev Set exchange rate DPT/ETH value. 
    */
    function setRate(uint256 newRate) public auth {
        rate = newRate;
    }
}
