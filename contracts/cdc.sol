pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/token/BurnableToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";


/**
 * @title CDC
 * @dev CDC coin.
 */
contract CDC is Ownable, BurnableToken {

    string public constant name = "CDC";
    string public constant symbol = "CDC";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 16000000 * (10 ** uint256(decimals));

    uint256 public rate = 1 ether;

    /**
    * @dev Constructor that gives msg.sender all of existing tokens.
    */
    function CDC() public {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    }

    function setRate(uint256 newRate) public onlyOwner {
        rate = newRate;
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
    function buyTokens() public payable {
        require(validPurchase());
        uint256 weiAmount = msg.value;
        // calculate token amount to be transfered
        uint256 tokens = rate.mul(weiAmount).div(1 ether);
        forwardFundsToOwner();
        transferFromOwner(tokens);
    }

    /**
    * @dev Transfer tokens from owner.
    */
    function transferFromOwner(uint256 _value) private returns (bool) {
        require(msg.sender != address(0));
        require(_value <= balances[owner]);
        // SafeMath.sub will throw if there is not enough balance.
        balances[owner] = balances[owner].sub(_value);
        balances[msg.sender] = balances[msg.sender].add(_value);
        Transfer(owner, msg.sender, _value);
        return true;
    }

    /**
    * @dev Transfer eth to owner.
    */
    function forwardFundsToOwner() internal {
        owner.transfer(msg.value);
    }

    /**
    * @dev Return true if the transaction can buy tokens.
    */
    function validPurchase() internal view returns (bool) {
        bool nonZeroPurchase = msg.value != 0;
        return nonZeroPurchase;
    }

}
