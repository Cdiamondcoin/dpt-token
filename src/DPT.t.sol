
pragma solidity ^0.4.23;

import "ds-test/test.sol";
import "ds-token/base.sol";
import "./DPT.sol"; 

contract DPTTester {
    DPT public _dpt;
    
    constructor(DPT dpt) public {
        _dpt = dpt;
    }
}

contract DPTTest is DSTest {
    uint constant DPT_SUPPLY = (10 ** 7) * (10 ** 18);
    DPT dpt;
    DPTTester user;
    
    function setUp() public {
        dpt = new DPT();
        user = new DPTTester(dpt);
    }
    
    function testFailMint() public {
        dpt.mint(10 ether);
    }

    function testWeReallyGotAllTokens() public {
        dpt.transfer(user,DPT_SUPPLY);
        assertEq(dpt.balanceOf(this), 0);
    }

    function testFailSendMoreThanAvailable() public {
        dpt.transfer(user,DPT_SUPPLY + 1);
    }
}
