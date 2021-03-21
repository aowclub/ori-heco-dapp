pragma solidity ^0.6.0;

interface ILockStrategy {
    function lock(address locker, uint256 amount) external;
    function lockRate() external view  returns (uint256);
    function baseRate() external view  returns (uint256);
}
