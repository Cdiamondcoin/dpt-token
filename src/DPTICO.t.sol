pragma solidity ^0.4.18;

import "ds-test/test.sol";
import "ds-math/math.sol";
import "./DPTICO.sol"; 
import "./DPT.sol"; 

contract TestMedianizerLike {
    bytes32 _ethUSDRate;
    bool _feedValid;

    constructor(uint ethUSDRate, bool feedValid) public {
        _ethUSDRate = bytes32(ethUSDRate);
        _feedValid = feedValid;
    }
    
    function setETHUSDRate(uint ethUSDRate) public {
        _ethUSDRate = bytes32(ethUSDRate);
    }
    
    function setValid(bool feedValid) public {
        _feedValid = feedValid;
    }

    function peek() external view returns (bytes32, bool) {
        return (_ethUSDRate,_feedValid);
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
    uint ethUSDRate = 317.96 ether;
    uint dptUSDRate = 3.5 ether;
    
    function setUp() public {
        dpt = new DPT();
        feed = new TestMedianizerLike(ethUSDRate, true); 
        ico = new DPTICO(dpt, feed, dptUSDRate, ethUSDRate);
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
        assertEq(dpt.balanceOf(this),DPT_SUPPLY - (wdiv(wmul(ethUSDRate, sendEth), dptUSDRate)));
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
        assertEq(dpt.balanceOf(this),DPT_SUPPLY - (wdiv(wmul(ethUSDRate, sendEth), dptUSDRate)));
    }

    function testBuyTokensSetDptUsdRate() public {
        sendEth = 10 ether;
        dptUSDRate = 5 ether ;
        ico.setDPTRate(dptUSDRate);
        user.doBuyTokens(sendEth);
        assertEq(dpt.balanceOf(this),DPT_SUPPLY - (wdiv(wmul(ethUSDRate, sendEth), dptUSDRate)));
    }

    function testFailBuyTokensSetZeroDptUsdRate() public {
        ico.setDPTRate(0);
    }

    function testBuyTokensSetEthUsdRate() public {
        sendEth = 10 ether;
        ethUSDRate = 300 ether;
        feed.setETHUSDRate(ethUSDRate);
        user.doBuyTokens(sendEth);
        assertEq(dpt.balanceOf(this),DPT_SUPPLY - (wdiv(wmul(ethUSDRate, sendEth), dptUSDRate)));
    }

    function testBuyTokensSetEthUsdAndDptUsdRate() public {
        sendEth = 10 ether;
        ethUSDRate = 300 ether;
        dptUSDRate = 5 ether ;
        ico.setDPTRate(dptUSDRate);
        feed.setETHUSDRate(ethUSDRate);
        user.doBuyTokens(sendEth);
        assertEq(dpt.balanceOf(this),DPT_SUPPLY - (wdiv(wmul(ethUSDRate, sendEth), dptUSDRate)));
    }

    function testBuyTenTokensSetEthUsdAndDptUsdRateStatic() public {
        ico.setDPTRate(5 ether);
        feed.setETHUSDRate(20 ether);
        user.doBuyTokens(10 ether);
        assertEq(dpt.balanceOf(user), 40 ether);
    }

    function testBuyTokenSetManualEthUsdRateUpdate() public {
        sendEth = 10 ether;
        ethUSDRate = 300 ether;
        feed.setValid(false);
        ico.setManualUSDRate(true);
        ico.setETHRate(ethUSDRate);
        user.doBuyTokens(sendEth);
        assertEq(dpt.balanceOf(this),DPT_SUPPLY - (wdiv(wmul(ethUSDRate, sendEth), dptUSDRate)));
    }

    function testFailBuyTokenSetManualEthUsdRateUpdateIfManuaUSDRatelIsFalse() public {
        sendEth = 10 ether;
        ethUSDRate = 300 ether;
        ico.setETHRate(ethUSDRate);
        user.doBuyTokens(sendEth);
        assertEq(dpt.balanceOf(this),DPT_SUPPLY - (wdiv(wmul(ethUSDRate, sendEth), dptUSDRate)));
    }

    function testInvalidFeedDoesNotUpdateEthUsdRate() public {
        sendEth = 134 ether;
        uint feedEthUSDRate = 1400 ether; //should not equal to `ethUSDRate` if you want a reasonable test
        ico.setManualUSDRate(true);
        feed.setValid(false);
        feed.setETHUSDRate(feedEthUSDRate);
        user.doBuyTokens(sendEth);
        assertEq(dpt.balanceOf(user), wdiv(wmul(ethUSDRate, sendEth), dptUSDRate));
    }

    function testFailInvalidFeedFailsIfManualUpdateIsFalse() public {
        sendEth = 134 ether;
        ico.setManualUSDRate(false);
        feed.setValid(false);
        user.doBuyTokens(sendEth);
    }

    function testSetFeed() public {
        sendEth = 10 ether;
        ethUSDRate = 2000 ether;
        TestMedianizerLike feed1 = new TestMedianizerLike(ethUSDRate, true);
        ico.setPriceFeed(feed1);
        user.doBuyTokens(sendEth);
        assertEq(dpt.balanceOf(user), wdiv(wmul(ethUSDRate, sendEth), dptUSDRate));
    }

    function testFailSetZeroAddressFeed() public {
        TestMedianizerLike feed1 ;
        ico.setPriceFeed(feed1);
    }
}
