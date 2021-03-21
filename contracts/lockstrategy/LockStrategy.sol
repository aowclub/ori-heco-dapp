pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "../lib/SafeERC20.sol";
import "../lib/Governance.sol";
import "../interface/IERC20.sol";
import "../lib/EnumerableSet.sol";
import "../lib/Math.sol";


contract LockStrategy is Governance {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 public _sfi = IERC20(0xAf2E29d4A2EEcbe4fdFe61540029fD1A1Ce20269);


    uint256 public _baseRate = 10000;
    uint256 private _lockRate = 7000;
    uint256 private _unlockRate = 3000;

    uint256 private _totalLocked;
    uint256 private _totalInterestOutput;

    mapping(address => uint256) private _balances;
    EnumerableSet.AddressSet private _callers;

    uint256 public _interestRate = 200;
    uint256 public _interestBase = 10000;

    uint256 public _lockPeriod = 1 days;

    struct LockInfo {
        uint256 startTime;
        uint256 amount;
        uint256 interest;
        bool claimed;
    }

    mapping(address => uint256) public _addressXId;
    mapping(address => mapping(uint256 => LockInfo)) public _lockTable;

    event Locked(address indexed user,uint256 lock_id,uint256 amount, uint256 interest);
    event Claimed(address indexed user,uint256 lock_id, uint256 amount);
    event ClaimedInterest(address indexed user,uint256 lock_id, uint256 amount);


    modifier onlyCaller() {
        require(_callers.contains(msg.sender), "not caller");
        _;
    }

    function totalLocked() public view returns (uint256) {
        return _totalLocked;
    }

    function totalInterestOutput() public view returns (uint256) {
        return _totalInterestOutput;
    }


    function setBaseRate(uint256 baseRate) external onlyGovernance {
        _baseRate = baseRate;
    }

    function setLockRate(uint256 lockRate) external onlyGovernance {
        _lockRate = lockRate;
    }

    function setUnlockRate(uint256 unlockRate) external onlyGovernance {
        _unlockRate = unlockRate;
    }

    function setCaller(address caller) external onlyGovernance{
        // Adds caller to callers array
        if (!_callers.contains(caller)) {
            _callers.add(caller);
        }
    }

    function removeCaller(address calller) external onlyGovernance {
        // Remove caller from callers array
        if(_callers.contains(calller)) {
            _callers.remove(calller);
        }
    }

    function lockRate() public view  returns (uint256) {
        return _lockRate;
    }

    function baseRate() public view  returns (uint256) {
        return _baseRate;
    }

    // get lock record list
    function getLockRecords(address user, uint256 start, uint256 count) public view returns (LockInfo[] memory records) {
        uint256 end = start.add(count);
        end = Math.min(end,_addressXId[user]);
        if(start >= end) {
            return records;
        }

        count = end-start;
        uint256 idx = count;
        LockInfo memory record;
        records = new LockInfo[](idx);
        for (uint256 i = --end; i >= start; i--) {
            record = _lockTable[user][i];
            records[count-(idx--)] = record;
            if (i == 0) {
                break;
            }
        }
    }

    function lock(address locker, uint256 amount) external onlyCaller {
        if(amount > 0) {
            uint256 lockId = _addressXId[locker];
            _addressXId[locker] = lockId + 1;

            LockInfo memory lock;
            lock.amount = amount;
            lock.startTime = block.timestamp;
            lock.interest = amount.mul(_interestRate).div(_interestBase);
            lock.claimed = false;
            _lockTable[locker][lockId] = lock;

            _totalLocked = _totalLocked.add(amount);
            emit Locked(locker,lockId,amount,lock.interest);
        }
    }

    function claim(uint256 lockId) public {
        require(lockId < _addressXId[msg.sender],"Illegal lock id");
        LockInfo memory lock = _lockTable[msg.sender][lockId];
        require(lock.startTime + _lockPeriod <= block.timestamp,"The lock id is unlock");
        uint256 amount = lock.amount;
        uint256 interest = lock.interest;

        _sfi.safeTransfer(msg.sender,amount);
        _sfi.safeTransfer(msg.sender,interest);

        lock.claimed = true;
        _lockTable[msg.sender][lockId] = lock;

        _totalLocked = _totalLocked.sub(amount);
        _totalInterestOutput = _totalInterestOutput.add(interest);
        emit Claimed(msg.sender,lockId,amount);
        emit ClaimedInterest(msg.sender,lockId,amount);
    }
}
