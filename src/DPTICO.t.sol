pragma solidity ^0.4.18;

import "ds-test/test.sol";
import "ds-math/math.sol";
import "./DPTICO.sol"; 
import "./DPT.sol"; 

contract TestMedianizerLike {
    bytes32 public ethUsdRate;
    bool public feedValid;

    constructor(uint ethUsdRate_, bool feedValid_) public {
        ethUsdRate = bytes32(ethUsdRate_);
        feedValid = feedValid_;
    }
    
    function setEthUsdRate(uint ethUsdRate_) public {
        ethUsdRate = bytes32(ethUsdRate_);
    }
    
    function setValid(bool feedValid_) public {
        feedValid = feedValid_;
    }

    function peek() external view returns (bytes32, bool) {
        return (ethUsdRate,feedValid);
    } 
}

contract DPTICOTester {
    DPTICO public _ico;
    
    constructor(DPTICO ico) public {
        _ico = ico;
    }

    function doBuyTokens(uint amount) public {
        _ico.buyTokens.value(amount)();    
    }

    function () external payable {
    }
}

contract DPTICOTest is DSTest, DSMath, DPTICOEvents {
    uint constant DPT_SUPPLY = (10 ** 7) * (10 ** 18);
    DPT dpt;
    TestMedianizerLike feed;
    DPTICO ico;
    DPTICOTester user;
    uint etherBalance ;
    uint sendEth;
    uint ethUsdRate = 317.96 ether;
    uint dptUsdRate = 3.5 ether;
    
    function setUp() public {
        dpt = new DPT();
        feed = new TestMedianizerLike(ethUsdRate, true); 
        ico = new DPTICO(dpt, feed, dptUsdRate, ethUsdRate);
        user = new DPTICOTester(ico);
        dpt.approve(ico, uint(-1));
        require(dpt.balanceOf(this) == DPT_SUPPLY);
        require(address(this).balance >= 1000 ether);
        address(user).transfer(1000 ether);
        etherBalance = address(this).balance;
    }
    
    function () external payable {
    }
    
    function buyTokens(uint sendValue) private {
        ico.buyTokens.value(sendValue)(); 
    }

    function testWeBuyTenTokens() public {
        sendEth = 10 ether;
        buyTokens(sendEth);
    }

    function testOthersBuyTenTokens() public {
        sendEth = 10 ether;
        user.doBuyTokens(sendEth);
        assertEq(dpt.balanceOf(this),DPT_SUPPLY - (wdiv(wmul(ethUsdRate, sendEth), dptUsdRate)));
    }

    function testFailBuyTenTokensIfIcoStopped() public {
        sendEth = 10 ether;
        ico.stop();
        buyTokens(sendEth);
    }

    function testICOCanBeRestarted() public {
        sendEth = 10 ether;
        ico.stop();
        ico.start();
        buyTokens(sendEth);
    }

    function testFailIfNoValueTransferred() public {
        buyTokens(0 ether);
    }

    function testFailBuyMaxTokensIfIcoStopped() public {
        //uint(-1) is the largest unsigned integer that can be represented with uint256
        buyTokens(uint(-1));
    }
    
    function testEthSentToOwner() public {
        sendEth = 10 ether;
        user.doBuyTokens(sendEth);
        assertEq(etherBalance + sendEth, address(this).balance);
    }

    function testBuyTokens() public {
        sendEth = 10 ether;
        user.doBuyTokens(sendEth);
        assertEq(dpt.balanceOf(this),DPT_SUPPLY - (wdiv(wmul(ethUsdRate, sendEth), dptUsdRate)));
    }

    function testBuyTokensSetDptUsdRate() public {
        sendEth = 10 ether;
        dptUsdRate = 5 ether ;
        ico.setDptRate(dptUsdRate);
        user.doBuyTokens(sendEth);
        assertEq(dpt.balanceOf(this),DPT_SUPPLY - (wdiv(wmul(ethUsdRate, sendEth), dptUsdRate)));
    }

    function testFailBuyTokensSetZeroDptUsdRate() public {
        ico.setDptRate(0);
    }

    function testBuyTokensSetEthUsdRate() public {
        sendEth = 10 ether;
        ethUsdRate = 300 ether;
        feed.setEthUsdRate(ethUsdRate);
        user.doBuyTokens(sendEth);
        assertEq(dpt.balanceOf(this),DPT_SUPPLY - (wdiv(wmul(ethUsdRate, sendEth), dptUsdRate)));
    }

    function testBuyTokensSetEthUsdAndDptUsdRate() public {
        sendEth = 10 ether;
        ethUsdRate = 300 ether;
        dptUsdRate = 5 ether ;
        ico.setDptRate(dptUsdRate);
        feed.setEthUsdRate(ethUsdRate);
        user.doBuyTokens(sendEth);
        assertEq(dpt.balanceOf(this),DPT_SUPPLY - (wdiv(wmul(ethUsdRate, sendEth), dptUsdRate)));
    }

    function testBuyTenTokensSetEthUsdAndDptUsdRateStatic() public {
        ico.setDptRate(5 ether);
        feed.setEthUsdRate(20 ether);
        user.doBuyTokens(10 ether);
        assertEq(dpt.balanceOf(user), 40 ether);
    }

    function testBuyTokenSetManualEthUsdRateUpdate() public {
        sendEth = 10 ether;
        ethUsdRate = 300 ether;
        feed.setValid(false);
        ico.setManualUsdRate(true);
        ico.setEthRate(ethUsdRate);
        user.doBuyTokens(sendEth);
        assertEq(dpt.balanceOf(this),DPT_SUPPLY - (wdiv(wmul(ethUsdRate, sendEth), dptUsdRate)));
    }

    function testFailBuyTokenSetManualEthUsdRateUpdateIfManuaUsdRatelIsFalse() public {
        sendEth = 10 ether;
        ethUsdRate = 300 ether;
        ico.setEthRate(ethUsdRate);
        user.doBuyTokens(sendEth);
        assertEq(dpt.balanceOf(this),DPT_SUPPLY - (wdiv(wmul(ethUsdRate, sendEth), dptUsdRate)));
    }

    function testInvalidFeedDoesNotUpdateEthUsdRate() public {
        sendEth = 134 ether;
        uint feedEthUsdRate = 1400 ether; //should not equal to `ethUsdRate` if you want a reasonable test
        ico.setManualUsdRate(true);
        feed.setValid(false);
        feed.setEthUsdRate(feedEthUsdRate);
        user.doBuyTokens(sendEth);
        assertEq(dpt.balanceOf(user), wdiv(wmul(ethUsdRate, sendEth), dptUsdRate));
    }

    function testFailInvalidFeedFailsIfManualUpdateIsFalse() public {
        sendEth = 134 ether;
        ico.setManualUsdRate(false);
        feed.setValid(false);
        user.doBuyTokens(sendEth);
    }

    function testSetFeed() public {
        sendEth = 10 ether;
        ethUsdRate = 2000 ether;
        TestMedianizerLike feed1 = new TestMedianizerLike(ethUsdRate, true);
        ico.setPriceFeed(feed1);
        user.doBuyTokens(sendEth);
        assertEq(dpt.balanceOf(user), wdiv(wmul(ethUsdRate, sendEth), dptUsdRate));
    }

    function testFailSetZeroAddressFeed() public {
        TestMedianizerLike feed1 ;
        ico.setPriceFeed(feed1);
    }
}
