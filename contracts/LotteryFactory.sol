//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Lottery.sol";

contract LotteryFactory is Ownable {
    Lottery[] private _lotteries;

    address internal immutable vrfCoordinator;
    bytes32 internal immutable keyHash;
    uint64 internal immutable subscriptionId;
    uint32 internal callbackGasLimit;
    uint16 internal requestConfirmations;

    constructor(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations
    ) {
        console.log("Deploying a LotteryFactory");
        vrfCoordinator = _vrfCoordinator;
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
    }

    function createLottery(
        uint _startAfter,
        uint _duration,
        uint _ticketPrice
    ) public onlyOwner {
        Lottery lottery = new Lottery(
            owner(),
            _startAfter,
            _duration,
            _ticketPrice,
            vrfCoordinator,
            keyHash,
            subscriptionId,
            callbackGasLimit,
            requestConfirmations
        );
        _lotteries.push(lottery);
    }

    function allLotteries() public view returns (Lottery[] memory) {
        return _lotteries;
    }

    function lastLotteries() public view returns (Lottery) {
        require(_lotteries.length > 0, "LotteryFactory: no lottery yet");
        return _lotteries[_lotteries.length - 1];
    }

    function updateCallbackGasLimit(uint32 _callbackGasLimit) internal virtual onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    function updateRequestConfirmations(uint16 _requestConfirmations) internal virtual onlyOwner {
        requestConfirmations = _requestConfirmations;
    }
}
