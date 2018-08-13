pragma solidity ^0.4.23;

import "ds-math/math.sol";
import "ds-auth/auth.sol";
import "ds-token/token.sol";
import "ds-stop/stop.sol";

contract MedianizerLike {
    function peek() external view returns (bytes32, bool); 
}
/**
 * @title DPT
 * @dev DPTICO contract.
 */
contract DPTICOEvents {
    event TokenBought(address owner, address sender, uint dptValue, uint _ethUSDRate, uint _dptUSDRate);
    event FeedValid(bool feedValid);
}
contract DPTICO is DSAuth, DSStop, DSMath, DPTICOEvents {
    uint public rate = 1 ether;         //set exchange rate of 1 DPT/ETH
    uint public _dptUSDRate;            //usd price of 1 DPT token. 18 digit precision
    uint public _ethUSDRate;            //price of ETH in USD. 18 digit precision
    MedianizerLike public _priceFeed;   //address of the Makerdao price feed
    bool public feedValid;              //if true feed has valid USD/ETH rate
    DSToken public _dpt;                //DPT token contract

    /**
    * @dev Constructor that gives msg.sender all of existing tokens.
    */
    constructor(DSToken dpt, MedianizerLike priceFeed, uint usdPrice, uint etherUsdRate) public {
         _dpt = dpt;
         _priceFeed = priceFeed;
         _dptUSDRate = usdPrice;
         _ethUSDRate = etherUsdRate;
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
        bool feedValidSave = feedValid;
        require(msg.value != 0);
        (bytes32 ethUSDRateB, feedValid) = _priceFeed.peek();
        if(feedValidSave != feedValid) { emit FeedValid(feedValid); }
        require(feedValid || _manualUSDRate);
        _ethUSDRate = uint(ethUSDRateB);
        tokens = wdiv(wmul(_ethUSDRate, msg.value), _dptUSDRate);
        address(owner).transfer(msg.value);
        _dpt.transferFrom(owner, msg.sender, tokens);
        emit TokenBought(owner, msg.sender, tokens, _ethUSDRate, _dptUSDRate);
    }

    /**
    * @dev Set exchange rate DPT/USD value. 
    */
    function setUSDRate(uint256 dptUSDRate) public auth {
        _dptUSDRate = dptUSDRate;
    }

    /**
    * @dev Set exchange rate DPT/ETH value manually.
    * 
    * This function should only be used if the _priceFeed does not return
    * valid price data.
    *
    */
    function setETHRate(uint256 dptUSDRate) public auth {
        require(_manualUSDRate);
        _ethUSDRate = dptUSDRate;
    }

    /**
    * @dev Set the price feed
    */
    function setPriceFeed(address priceFeed) public auth {
        _priceFeed = priceFeed;
    }

    /**
    * @dev Set manual feed update
    * 
    * If _manualUSDRate is true, then buyTokens() will calculate the DPT amount based on latest valid _ethUSDRate, 
    * so _ethUSDRate must be updated by admins if _priceFeed fails to provide valid price data.
    * 
    * If _manualUSDRate is false, then buyTokens() will simply revert if _priceFeed does not provide valid price data.
    */
    function setManualUSDRate(bool manualUSDRate) public auth {
        _manualUSDRate = manualUSDRate;
    }
}
