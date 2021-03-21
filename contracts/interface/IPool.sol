pragma solidity ^0.6.0;


interface IPool {
    function totalSupply( ) external view virtual returns (uint256);
    function balanceOf( address player ) external view virtual returns (uint256);
}
