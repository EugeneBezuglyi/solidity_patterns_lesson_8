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

    mapping(uint => address) internal requestToSender;
    uint internal requestsWaiting;

    mapping(uint16 => address[]) internal ticketParticipants;
    mapping(address => uint16[]) internal participantTickets;
    uint16 internal maxCurrentTicket;

    uint internal ownerProfit;
    uint internal participantProfit;
    mapping(address => bool) internal transferred;

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
        requestsWaiting++;


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
        requestsWaiting--;
    }

    function myTickets() public view returns (uint16[] memory) {
        return participantTickets[msg.sender];
    }

    function withdraw() external timedTransitions atStage(Stages.FINISHED) {
        require(requestsWaiting == 0, "Lottery: Wait until all users will get their tickets");
        if (ownerProfit == 0) {
            uint currentBalance = address(this).balance;
            ownerProfit = currentBalance / 10;
            uint participantsProfit = currentBalance - ownerProfit;
            participantProfit = participantsProfit / ticketParticipants[maxCurrentTicket].length;
        }
        if (!transferred[msg.sender]) {
            if (owner == msg.sender) {
                (bool sent,) = owner.call{value : ownerProfit}("");
                require(sent, "Lottery: Failed to send Ether to owner");
            } else {
                bool doesUserWin = false;
                for (uint i = 0; i < min(MAX_ALLOWED_TICKETS, participantTickets[msg.sender].length); i++) {
                    if (participantTickets[msg.sender][i] == maxCurrentTicket) {
                        doesUserWin = true;
                        break;
                    }
                }
                if (doesUserWin) {
                    (bool sent,) = msg.sender.call{value : participantProfit}("");
                    require(sent, "Lottery: Failed to send Ether");
                }
            }
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
