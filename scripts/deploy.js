const hre = require("hardhat");
const [
    vrfCoordinator,
    keyHash,
    subscriptionId,
    callbackGasLimit,
    requestConfirmations
] = require("./argumentsFactory.js");

async function main() {
    const LotteryFactory = await hre.ethers.getContractFactory("LotteryFactory");
    const lotteryFactory = await LotteryFactory.deploy(
        vrfCoordinator,
        keyHash,
        subscriptionId,
        callbackGasLimit,
        requestConfirmations
    );

    await lotteryFactory.deployed();

    console.log("LotteryFactory deployed to:", lotteryFactory.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
