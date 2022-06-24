const factoryArguments = require("./argumentsFactory.js");

const owner = "0x082124E91cb11f78F2E9977C6acf691EE32558a6";
const startAfter = 60;
const duration = 600
const ticketPrice = "1000000000000000" // 0.001

module.exports = [
    owner,
    startAfter,
    duration,
    ticketPrice,
    ...factoryArguments,
];