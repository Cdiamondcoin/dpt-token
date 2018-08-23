pragma solidity ^0.4.23;

import "ds-math/math.sol";
import "ds-auth/auth.sol";
import "ds-token/token.sol";
import "ds-stop/stop.sol";
import "ds-note/note.sol";

contract MedianizerLike {
    function peek() external view returns (bytes32, bool);
}

/**
 * @title DPT
 * @dev DPTICO contract.
 */
contract DPTICOEvents {
    event LogBuyToken(
        address owner,
        address sender,
        uint ethValue,
        uint dptValue,
        uint ethUsdRate,
        uint dptUsdRate
    );
    event LogFeedValid(bool feedValid);
}

contract DPTICO is DSAuth, DSStop, DSMath, DPTICOEvents {
    uint public dptUsdRate;            //usd price of 1 DPT token. 18 digit precision
    uint public ethUsdRate;            //price of ETH in USD. 18 digit precision
    MedianizerLike public priceFeed;   //address of the Makerdao price feed
    bool public feedValid;             //if true feed has valid USD/ETH rate
    ERC20 public dpt;                  //DPT token contract
    bool public manualUsdRate = true;  //if true enables token buy even if priceFeed does not provide valid data

    /**
    * @dev Constructor
    */
    constructor(address dpt_, address priceFeed_, uint dptUsdRate_, uint ethUsdRate_) public {
        dpt = ERC20(dpt_);
        priceFeed = MedianizerLike(priceFeed_);
        dptUsdRate = dptUsdRate_;
        ethUsdRate = ethUsdRate_;
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
        bytes32 ethUsdRateB;
        require(msg.value != 0, "Invalid amount");

        // receive ETH/USD price from external feed
        (ethUsdRateB, feedValid) = priceFeed.peek();

        // emit LogFeedValid event if validity of feed changes
        if (feedValidSave != feedValid) {
            emit LogFeedValid(feedValid);
        }

        // if feed is valid, load ETH/USD rate from it
        if (feedValid) {
            ethUsdRate = uint(ethUsdRateB);
        } else {
            // if feed invalid revert if manualUSDRate_ is NOT allowed
            require(manualUsdRate, "Manual rate not allowed");
        }

        tokens = wdiv(wmul(ethUsdRate, msg.value), dptUsdRate);
        address(owner).transfer(msg.value);
        dpt.transferFrom(owner, msg.sender, tokens);
        emit LogBuyToken(owner, msg.sender, msg.value, tokens, ethUsdRate, dptUsdRate);
    }

    /**
    * @dev Get tokenAmount price in ETH
    */
    function getPrice(uint tokenAmount) public view returns (uint) {
        bool feedValid_;
        uint ethUsdRate_;
        bytes32 ethUsdRateB;
        require(tokenAmount > 0, "Invalid amount");

        // receive ETH/USD price from external feed
        (ethUsdRateB, feedValid_) = priceFeed.peek();

        if (feedValid_) {
            ethUsdRate_ = uint(ethUsdRateB);
        } else {
            // load manual ETH/USD rate if enabled
            require(manualUsdRate, "Manual rate not allowed");
            ethUsdRate_ = ethUsdRate;
        }

        return wdiv(wmul(tokenAmount, dptUsdRate), ethUsdRate_);
    }

    /**
    * @dev Set exchange rate DPT/USD value.
    */
    function setDptRate(uint dptUsdRate_) public auth note {
        require(dptUsdRate_ > 0, "Invalid amount");
        dptUsdRate = dptUsdRate_;
    }

    /**
    * @dev Set exchange rate DPT/ETH value manually.
    *
    * This function should only be used if the priceFeed does not return
    * valid price data.
    *
    */
    function setEthRate(uint ethUsdRate_) public auth note {
        require(manualUsdRate, "Manual rate not allowed");
        ethUsdRate = ethUsdRate_;
    }

    /**
    * @dev Set the price feed
    */
    function setPriceFeed(address priceFeed_) public auth note {
        require(priceFeed_ != 0x0, "Wrong PriceFeed address");
        priceFeed = MedianizerLike(priceFeed_);
    }

    /**
    * @dev Set manual feed update
    *
    * If `manualUsdRate` is true, then `buyTokens()` will calculate the DPT amount based on latest valid `ethUsdRate`,
    * so `ethUsdRate` must be updated by admins if priceFeed fails to provide valid price data.
    *
    * If manualUsdRate is false, then buyTokens() will simply revert if priceFeed does not provide valid price data.
    */
    function setManualUsdRate(bool manualUsdRate_) public auth note {
        manualUsdRate = manualUsdRate_;
    }
}
