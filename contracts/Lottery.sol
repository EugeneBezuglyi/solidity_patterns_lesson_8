//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Lottery is VRFConsumerBaseV2 {

    enum Stages {
        NEW,
        IN_PROGRESS,
        FINISHED
    }

    event RandomnessRequested(uint256 indexed requestId);

    uint8 public constant MAX_ALLOWED_TICKETS = 10;
    uint16 public constant MAX_TICKET_NUMBER = 1000;

    Stages public stage = Stages.NEW;
    uint public immutable creationTime = block.timestamp;
    address public immutable owner;
    uint public immutable startAfter;
    uint public immutable duration;
    uint public immutable ticketPrice;

    VRFCoordinatorV2Interface internal immutable vrfCoordinator;
    bytes32 internal immutable keyHash;
    uint64 internal immutable subscriptionId;
    uint32 internal immutable callbackGasLimit;
    uint16 internal immutable requestConfirmations;

    mapping(uint => address) requestToSender;
    mapping(uint16 => address[]) public ticketParticipants;
    mapping(address => uint16[]) public participantTickets;
    uint16 public maxCurrentTicket;

    constructor(
        address _owner,
        uint _startAfter,
        uint _duration,
        uint _ticketPrice,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        console.log("Deploying a Lottery that start after", _startAfter);
        owner = _owner;
        startAfter = _startAfter;
        duration = _duration;
        ticketPrice = _ticketPrice;
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
    }

    modifier atStage(Stages _stage) {
        require(stage == _stage, "Lottery: not allowed yet");
        _;
    }

    modifier timedTransitions() {
        if (stage == Stages.NEW && block.timestamp >= creationTime + startAfter) {
            stage = Stages.IN_PROGRESS;
        } else if (stage == Stages.IN_PROGRESS && block.timestamp >= creationTime + startAfter + duration) {
            stage = Stages.FINISHED;
        }
        _;
    }

    function buy() payable public timedTransitions atStage(Stages.IN_PROGRESS) {
        require(msg.value >= ticketPrice, "Lottery: value not enough");
        uint8 ticketAmount;
        if (msg.value >= MAX_ALLOWED_TICKETS * ticketPrice) {
            ticketAmount = MAX_ALLOWED_TICKETS;
        } else {
            ticketAmount = uint8(msg.value / ticketPrice);
        }
        uint8 userTicketLength = uint8(participantTickets[msg.sender].length);
        if (userTicketLength + ticketAmount > MAX_ALLOWED_TICKETS) {
            ticketAmount = MAX_ALLOWED_TICKETS - userTicketLength;
            require(ticketAmount > 0, "Lottery: ticket limit");
        }

        uint requestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            ticketAmount
        );

        requestToSender[requestId] = msg.sender;


        uint ticketsPrice = ticketAmount * ticketPrice;
        if (msg.value > ticketsPrice) {
            payable(msg.sender).transfer(msg.value - ticketsPrice);
        }
        emit RandomnessRequested(requestId);
    }


    function fulfillRandomWords(uint256 requestId, uint256[] memory randomNumbers) internal override {
        for (uint i = 0; i < randomNumbers.length; i++) {
            uint16 ticket = uint16((randomNumbers[i] % MAX_TICKET_NUMBER) + 1);
            if (maxCurrentTicket < ticket) {
                maxCurrentTicket = ticket;
            }
            address sender = requestToSender[requestId];
            ticketParticipants[ticket].push(sender);
            participantTickets[sender].push(ticket);
        }
    }

    function myTickets() public view returns (uint16[] memory) {
        return participantTickets[msg.sender];
    }

    function withdraw() external timedTransitions atStage(Stages.FINISHED) {
        require(owner == msg.sender, "Lottery: only owner");
        uint currentBalance = address(this).balance;
        uint ownerProfit = currentBalance / 10;
        uint participantsProfit = currentBalance - ownerProfit;
        uint participantProfit = participantsProfit / ticketParticipants[maxCurrentTicket].length;

        payable(owner).transfer(ownerProfit);
        for (uint i = 0; i < ticketParticipants[maxCurrentTicket].length; i++) {
            payable(ticketParticipants[maxCurrentTicket][i]).transfer(participantProfit);
        }
    }
}
