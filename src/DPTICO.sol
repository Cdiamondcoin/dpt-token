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
    event LogBuyToken(address owner, address sender, uint dptValue, uint _ethUSDRate, uint _dptUSDRate);
    event LogFeedValid(bool feedValid);
    event LogDptUsdRate(uint _dptUSDRate);
    event LogEthUsdRate(uint _ethUSDRate);
    event LogPriceFeed(address _priceFeed);
    event LogManualUSDRate(bool _manualUSDRate);
}

contract DPTICO is DSAuth, DSStop, DSMath, DPTICOEvents {
    uint public rate = 1 ether;         //set exchange rate of 1 DPT/ETH
    uint public _dptUSDRate;            //usd price of 1 DPT token. 18 digit precision
    uint public _ethUSDRate;            //price of ETH in USD. 18 digit precision
    MedianizerLike public _priceFeed;   //address of the Makerdao price feed
    bool public feedValid;              //if true feed has valid USD/ETH rate
    DSToken public _dpt;                //DPT token contract
    bool public _manualUSDRate;         //if true enables token buy even if _priceFeed does not provide valid data

    /**
    * @dev Constructor that gives msg.sender all of existing tokens.
    */
    constructor(address dpt, address priceFeed, uint dptUSDRate, uint etherUsdRate) public {
         _dpt = DSToken(dpt);
         _priceFeed = MedianizerLike(priceFeed);
         _dptUSDRate = dptUSDRate;
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
        bytes32 ethUSDRateB;
        require(msg.value != 0);
        
        (ethUSDRateB, feedValid) = _priceFeed.peek();           //receive ETH/USD price from external feed
        if(feedValidSave != feedValid) { emit LogFeedValid(feedValid); }   //emit LogFeedValid event if validity of feed changes
        if(feedValid) {                                                 //if feed is valid, load ETH/USD rate from it
            _ethUSDRate = uint(ethUSDRateB); 
        }else{
            require(_manualUSDRate);
        }
        tokens = wdiv(wmul(_ethUSDRate, msg.value), _dptUSDRate);
        address(owner).transfer(msg.value);
        _dpt.transferFrom(owner, msg.sender, tokens);
        emit LogBuyToken(owner, msg.sender, tokens, _ethUSDRate, _dptUSDRate);
    }

    /**
    * @dev Set exchange rate DPT/USD value. 
    */
    function setDPTRate(uint dptUSDRate) public auth {
        require(dptUSDRate > 0);
        _dptUSDRate = dptUSDRate;
        emit LogDptUsdRate(_dptUSDRate);
    }

    /**
    * @dev Set exchange rate DPT/ETH value manually.
    * 
    * This function should only be used if the _priceFeed does not return
    * valid price data.
    *
    */
    function setETHRate(uint ethUSDRate) public auth {
        require(_manualUSDRate);
        _ethUSDRate = ethUSDRate;
        emit LogEthUsdRate(_ethUSDRate);
    }

    /**
    * @dev Set the price feed
    */
    function setPriceFeed(address priceFeed) public auth {
        require(priceFeed != 0x0);
        _priceFeed = MedianizerLike(priceFeed);
        emit LogPriceFeed(address(_priceFeed));
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
        emit LogManualUSDRate(_manualUSDRate);
    }
}
