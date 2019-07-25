pragma solidity ^0.4.25;

contract AnybodyCanCallAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool) {
        return true;
    }
}
