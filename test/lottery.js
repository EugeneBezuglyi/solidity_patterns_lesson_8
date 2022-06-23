const {expect} = require("chai");
const {ethers, network} = require("hardhat");

describe("Lottery", function () {
    let owner;
    let alice, bob;
    let lotteryFactory, vrfCoordinatorV2Mock;
    let subscriptionId;
    const keyHash = `0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc`;
    const callbackGasLimit = `1000000`;
    const requestConfirmations = `3`;

    beforeEach(async () => {
        [owner, alice, bob] = await ethers.getSigners();
        const LotteryFactory = await ethers.getContractFactory("LotteryFactory");
        const VRFCoordinatorV2Mock = await ethers.getContractFactory("VRFCoordinatorV2Mock");

        vrfCoordinatorV2Mock = await VRFCoordinatorV2Mock.deploy(0, 0);

        const tx = await vrfCoordinatorV2Mock.createSubscription();
        const txReceipt = await tx.wait();
        subscriptionId = txReceipt.logs[0].topics[1];
        await vrfCoordinatorV2Mock.fundSubscription(subscriptionId, ethers.utils.parseEther(`1`));
        console.log("subscriptionId", subscriptionId)

        lotteryFactory = await LotteryFactory.deploy(
            vrfCoordinatorV2Mock.address,
            keyHash,
            subscriptionId,
            callbackGasLimit,
            requestConfirmations
        );
        console.log(lotteryFactory.address);
    })


    it("Intergation test", async function () {
        const startAfter = 60;
        const duration = 600;
        const ticketPrice = ethers.utils.parseEther("0.1")

        lotteryFactory.createLottery(startAfter, duration, ticketPrice)
        const lotteryAddress = await lotteryFactory.lastLotteries()

        const Lottery = await ethers.getContractFactory("Lottery");
        const lottery = await Lottery.attach(lotteryAddress);

        await expect(lottery.connect(alice).buy({
            value: ethers.utils.parseEther("2.0")
        })).to.be.revertedWith("Lottery: not allowed yet")

        await increaseTime(startAfter);

        await buy(lottery, alice, "0.2");
        let aliceTickets = await getTickets(lottery, alice)
        expect(aliceTickets.length).to.equal(2)
        console.log(aliceTickets)

        for (let i = 0; i < 10; i++) {
            await buy(lottery, bob, "0.1");
        }
        await expect(buy(lottery, bob, "0.1")).to.be.revertedWith("Lottery: ticket limit")
        let bobTickets = await getTickets(lottery, bob)
        console.log(bobTickets)

        await increaseTime(duration);

        await expect(lottery.connect(alice).buy({
            value: ethers.utils.parseEther("2.0")
        })).to.be.revertedWith("Lottery: not allowed yet")

        const ownerBalanceBefore = await getBalance(owner)

        await lottery.withdraw()

        const ownerBalanceAfter = await getBalance(owner)

        expectEtherChanged(ownerBalanceBefore, ownerBalanceAfter, "+0.12")
    });

    async function increaseTime(duration) {
        await network.provider.send("evm_increaseTime", [duration])
        await network.provider.send("evm_mine")
    }

    async function buy(lottery, provider, ether) {
        const tx = await lottery.connect(provider).buy({
            value: ethers.utils.parseEther(ether)
        });
        const rc = await tx.wait();
        const [requestId] = rc.events.find(event => event.event === 'RandomnessRequested').args
        await vrfCoordinatorV2Mock.fulfillRandomWords(requestId, lottery.address);
        return requestId;
    }

    async function getTickets(lottery, provider) {
        return await lottery.connect(provider).myTickets();
    }

    async function getBalance(signerOrProvider) {
        return {
            ether: await ethers.provider.getBalance(signerOrProvider.address)
        }
    }

    function expectEtherChanged(before, after, ether) {
        let current = parseFloat(ethers.utils.formatEther(after.ether - before.ether + "")).toFixed(2);
        current = current === '-0.00' ? "0.00" : current
        expect(parseFloat(ether).toFixed(2)).to.equal(current);
    }
});
