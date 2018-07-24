pragma solidity ^0.4.18;

import "ds-test/test.sol";
import "ds-math/math.sol";
import "./DPTICO.sol"; 
import "./DPT.sol"; 

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

contract DPTICOTest is DSTest, DSMath {
    uint constant DPT_SUPPLY = (10 ** 7) * (10 ** 18);
    DPT dpt;
    DPTICO ico;
    DPTICOTester user;
    uint etherBalance ;
    uint sendEth;
    
    function setUp() public {
        dpt = new DPT();
        ico = new DPTICO(dpt);
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
        assertEq(dpt.balanceOf(this),DPT_SUPPLY - (sendEth));
    }

    function testBuyTenTokensSetRate() public {
        sendEth = 10 ether;
        uint rate = 2 ether ;
        ico.setRate(rate);
        user.doBuyTokens(sendEth);
        assertEq(dpt.balanceOf(this),DPT_SUPPLY - (mul(rate , sendEth) / (1 ether)));
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
}
