pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "../interface/IERC20.sol";
import "../interface/ERC20.sol";
import "../interface/ILockStrategy.sol";
import "../lib/Math.sol";
import "../interface/IPool.sol";
import "../lib/Governance.sol";
import "../lib/SafeMath.sol";
import "../lib/SafeERC20.sol";


contract LPTokenWrapper is IPool,Governance {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public _lpToken = IERC20(0x499B6E03749B4bAF95F9E70EeD5355b138EA6C31);

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;


    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);

        _lpToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual{
        require(amount > 0, "amout > 0");

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);

        _lpToken.safeTransfer( msg.sender, amount);
    }
}

contract HT_USDT_StakingReward is LPTokenWrapper{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public _sfi = IERC20(0x117AF236b8deAf9C32cc5a1e04E5e8E481B7373a);

    address public _lockStrategy = address(0x0);


    uint256 public constant DURATION = 365 days;

    uint256 public _startTime =  now ;
    uint256 public _periodFinish = 0;
    uint256 public _rewardRate = 0;
    uint256 public _lastUpdateTime;
    uint256 public _rewardPerTokenStored;

    mapping(address => uint256) public _userRewardPerTokenPaid;
    mapping(address => uint256) public _rewards;
    mapping(address => uint256) public _lastStakedTime;

    bool public _hasStart = false;


    struct RewardRecord {
        uint256 rewardTime;
        uint256 amount;
    }

    mapping(address => uint256) public _rewardRecordId;
    mapping(address => mapping(uint256 => RewardRecord)) public _rewardRecordTable;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    function setLockStrategy(address strategy)  public  onlyGovernance{
        _lockStrategy = strategy;
    }

    modifier updateReward(address account) {
        _rewardPerTokenStored = rewardPerToken();
        _lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            _rewards[account] = earned(account);
            _userRewardPerTokenPaid[account] = _rewardPerTokenStored;
        }
        _;
    }

    /* Fee collection for any other token */
    function seize(IERC20 token, uint256 amount) external onlyGovernance{
        require(token != _sfi, "reward");
        require(token != _lpToken, "stake");
        token.safeTransfer(_governance, amount);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, _periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return _rewardPerTokenStored;
        }
        return
        _rewardPerTokenStored.add(
            lastTimeRewardApplicable()
            .sub(_lastUpdateTime)
            .mul(_rewardRate)
            .mul(1e18)
            .div(totalSupply())
        );
    }

    function earned(address account) public view returns (uint256) {
        return
        balanceOf(account)
        .mul(rewardPerToken().sub(_userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(_rewards[account]);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount)
    public
    override
    updateReward(msg.sender)
    checkStart
    {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);

        _lastStakedTime[msg.sender] = now;

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
    public
    override
    updateReward(msg.sender)
    checkStart
    {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) checkStart {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            _rewards[msg.sender] = 0;

            if( _lockStrategy != address(0x0)){
                ILockStrategy strategy = ILockStrategy(_lockStrategy);
                uint256 lockRate = strategy.lockRate();
                uint256 baseRate = strategy.baseRate();
                uint256 lock = reward.mul(lockRate).div(baseRate);
                _sfi.safeTransfer(_lockStrategy,lock);
                strategy.lock(msg.sender,lock);
                reward = reward.sub(lock);
            }

            _sfi.safeTransfer(msg.sender, reward );

            storeRewardRecord(msg.sender,block.timestamp,reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function storeRewardRecord(address user,uint256 rewardTime, uint256 amount) internal {
        uint256 recordId = _rewardRecordId[user];
        _rewardRecordId[user] = recordId + 1;
        RewardRecord memory record = _rewardRecordTable[user][recordId];
        record.amount = amount;
        record.rewardTime = rewardTime;
        _rewardRecordTable[user][recordId] = record;
    }

    // get reward record list
    function getRewardRecords(address user, uint256 start, uint256 count) public view returns (RewardRecord[] memory records) {
        uint256 end = start.add(count);
        end = Math.min(end,_rewardRecordId[user]);
        if(start >= end) {
            return records;
        }

        count = end-start;
        uint256 idx = count;
        RewardRecord memory record;
        records = new RewardRecord[](idx);
        for (uint256 i = --end; i >= start; i--) {
            record = _rewardRecordTable[user][i];
            records[count-(idx--)] = record;
            if (i == 0) {
                break;
            }
        }
    }

    // get lp price by given token
    function lpPrice(address token) public view returns (uint256 price) {
        uint256 value = IERC20(token).balanceOf(address (_lpToken));
        value = value.mul(2);
        uint256 lpTotalSupply = _lpToken.totalSupply();
        if(lpTotalSupply == 0) {
            return price;
        }
        uint256 baseDecimal = uint256(ERC20(token).decimals());
        uint256 lpDecimal = uint256(ERC20(address(_lpToken)).decimals());

        price = uint256(10**18).mul(uint256(10 ** lpDecimal)).mul(value).div(lpTotalSupply).div(uint256(10** baseDecimal));
    }

    modifier checkStart() {
        require(block.timestamp > _startTime, "not start");
        _;
    }

    // set fix time to start reward
    function startReward(uint256 startTime,uint256 reward)
    external
    onlyGovernance
    updateReward(address(0))
    {
        require(_hasStart == false, "has started");
        _hasStart = true;

        _startTime = startTime;

        _rewardRate = reward.div(DURATION);
        IERC20(_sfi).safeTransferFrom(msg.sender, address(this), reward);

        _lastUpdateTime = _startTime;
        _periodFinish = _startTime.add(DURATION);

        emit RewardAdded(reward);
    }

    //

    //for extra reward
    function notifyRewardAmount(uint256 reward)
    external
    onlyGovernance
    updateReward(address(0))
    {
        IERC20(_sfi).safeTransferFrom(msg.sender, address(this), reward);
        if (block.timestamp >= _periodFinish) {
            _rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = _periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(_rewardRate);
            _rewardRate = reward.add(leftover).div(DURATION);
        }
        _lastUpdateTime = block.timestamp;
        _periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }
}
