const { expect } = require("chai");
const hre = require("hardhat");
const ethers = require("ethers");

describe("lock测试用例", function() {


    beforeEach(async function() {
        [owner, alice, bob] = await hre.ethers.getSigners();

        factory = await hre.ethers.getContractFactory("LockStrategy");
        lock = await factory.deploy();
        await lock.deployed();
        console.log(`power=${lock.address}`)

        await lock.setCaller(owner.address);
    });

    it("test", async function(){

        await lock.lock(owner.address,ethers.utils.parseEther("100"));

        let totalLock = await lock.totalLocked();
        let interest = await lock.totalInterestOutput();
        console.log(ethers.utils.formatEther(totalLock));
        console.log(ethers.utils.formatEther(interest));
    });


});
