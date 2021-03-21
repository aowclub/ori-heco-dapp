let ethers = require("ethers");
let hre = require("hardhat")
let sfi = "0x117AF236b8deAf9C32cc5a1e04E5e8E481B7373a";

let startTime = parseInt(new Date().getTime()/1000);
const url = hre.network.config.url;
const provider = new ethers.providers.JsonRpcProvider(url);

let sleep = async (time) => {
    return await new Promise((resolve, reject) => {
        setTimeout(() => {
            resolve();
        }, time);
    });
}

async function waitConfirmed(hash) {
    console.log(`--hash=${hash}`);
    while (true) {
        let receipt = await provider.getTransactionReceipt(hash);
        if(receipt != null) {
            return;
        }
    }
    await sleep(10000);
}

async function main() {

    const SFIToken = await hre.ethers.getContractFactory("SFIToken");
    const sfiToken = SFIToken.attach(sfi);
    console.log(url);

    let [sender] = await hre.ethers.getSigners();
    console.log("sender:",sender.address);

    const LockStrategy = await hre.ethers.getContractFactory("LockStrategy");
    const lockStrategy = await LockStrategy.deploy();

    await lockStrategy.deployed();
    console.log("LockStrategy deployed to:", lockStrategy.address);

    let StakingReward = await hre.ethers.getContractFactory("SFI_USDT_StakingReward");
    const sfi_usdt = await StakingReward.deploy();
    await sfi_usdt.deployed();
    console.log("SFI-USDT-Staking deployed to:", sfi_usdt.address);
    let tx = await sfi_usdt.setLockStrategy(lockStrategy.address);
    await waitConfirmed(tx.hash);
    tx = await lockStrategy.setCaller(sfi_usdt.address);
    await waitConfirmed(tx.hash);
    let rewardValue = ethers.utils.parseEther("3000000");
    tx = await sfiToken.approve(sfi_usdt.address,rewardValue);
    await waitConfirmed(tx.hash);
    tx = await sfi_usdt.startReward(startTime,rewardValue);
    await waitConfirmed(tx.hash);


    StakingReward = await hre.ethers.getContractFactory("ORI_USDT_StakingReward");
    const ori_usdt = await StakingReward.deploy();
    await ori_usdt.deployed();
    console.log("ORI-USDT-Staking deployed to:", ori_usdt.address);
    tx = await ori_usdt.setLockStrategy(lockStrategy.address);
    await waitConfirmed(tx.hash);
    tx = await lockStrategy.setCaller(ori_usdt.address);
    await waitConfirmed(tx.hash);
    rewardValue = ethers.utils.parseEther("3000000");
    tx = await sfiToken.approve(ori_usdt.address,rewardValue);
    await waitConfirmed(tx.hash);
    tx = await ori_usdt.startReward(startTime,rewardValue);
    await waitConfirmed(tx.hash);


    StakingReward = await hre.ethers.getContractFactory("HUSD_USDT_StakingReward");
    const husd_usdt = await StakingReward.deploy();
    await husd_usdt.deployed();
    console.log("HUSD-USDT-Staking deployed to:", husd_usdt.address);
    tx = await husd_usdt.setLockStrategy(lockStrategy.address);
    await waitConfirmed(tx.hash);
    tx = await lockStrategy.setCaller(husd_usdt.address);
    await waitConfirmed(tx.hash);
    rewardValue = ethers.utils.parseEther("500000");
    tx = await sfiToken.approve(husd_usdt.address,rewardValue);
    await waitConfirmed(tx.hash);
    tx = await husd_usdt.startReward(startTime,rewardValue);
    await waitConfirmed(tx.hash);



    StakingReward = await hre.ethers.getContractFactory("ETH_USDT_StakingReward");
    const eth_usdt = await StakingReward.deploy();
    await eth_usdt.deployed();
    console.log("ETH-USDT-Staking deployed to:", eth_usdt.address);
    tx = await eth_usdt.setLockStrategy(lockStrategy.address);
    await waitConfirmed(tx.hash);
    tx = await lockStrategy.setCaller(eth_usdt.address);
    await waitConfirmed(tx.hash);
    rewardValue = ethers.utils.parseEther("500000");
    tx = await sfiToken.approve(eth_usdt.address,rewardValue);
    await waitConfirmed(tx.hash);
    tx = await eth_usdt.startReward(startTime,rewardValue);
    await waitConfirmed(tx.hash);


    StakingReward = await hre.ethers.getContractFactory("HT_USDT_StakingReward");
    const ht_usdt = await StakingReward.deploy();
    await ht_usdt.deployed();
    console.log("HT-USDT-Staking deployed to:", ht_usdt.address);
    tx = await ht_usdt.setLockStrategy(lockStrategy.address);
    await waitConfirmed(tx.hash);
    tx = await lockStrategy.setCaller(ht_usdt.address);
    await waitConfirmed(tx.hash);
    rewardValue = ethers.utils.parseEther("500000");
    tx = await sfiToken.approve(ht_usdt.address,rewardValue);
    await waitConfirmed(tx.hash);
    tx = await ht_usdt.startReward(startTime,rewardValue);
    await waitConfirmed(tx.hash);

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
