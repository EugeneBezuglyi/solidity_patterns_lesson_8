const vrfCoordinator = "0x6168499c0cFfCaCD319c818142124B7A15E857ab"
const keyHash = "0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc"
const subscriptionId = process.env.SUBSCRIPTION_ID;
const callbackGasLimit = 20_000 * 10
const requestConfirmations = 3

module.exports = [
    vrfCoordinator,
    keyHash,
    subscriptionId,
    callbackGasLimit,
    requestConfirmations
];