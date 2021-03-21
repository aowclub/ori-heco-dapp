require("hardhat");

async function main() {

    // const SFIToken = await hre.ethers.getContractFactory("SFIToken");
    // const sfi = await SFIToken.deploy();
    //
    // await sfi.deployed();
    //
    // console.log("SFI deployed to:", sfi.address);

    const ORIToken = await hre.ethers.getContractFactory("ORIToken");
    const ori = await ORIToken.deploy();

    await ori.deployed();

    console.log("ORI deployed to:", ori.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
