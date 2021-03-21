require("hardhat");
let ethers = require("ethers");

let sfi = "0xfAb4162B515f0458331096687976d7078e1751CA";
let lp = "0xAfD69D86FB393389039a23e08eD75f36E7e49D75";

let startTime = parseInt(new Date().getTime()/1000);
let rewardValue = ethers.utils.parseEther("3000000");
let usdt = "0xa71edc38d189767582c38a3145b5873052c3e47a";
async function main() {

    let [sender] = await hre.ethers.getSigners();
    console.log("sender:",sender.address);

    const StakingReward = await hre.ethers.getContractFactory("ETH_USDT_StakingReward");
    // const staking = await StakingReward.deploy();
    // await staking.deployed();
    // console.log("Staking deployed to:", staking.address);
    let staking_address = "0x65999eb3e2B6490D4AD8559DB05314474cAb59F1";
    let staking = StakingReward.attach(staking_address);

    const lpPrice = await staking.lpPrice(usdt);
    console.log(ethers.utils.formatEther(lpPrice));


}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
