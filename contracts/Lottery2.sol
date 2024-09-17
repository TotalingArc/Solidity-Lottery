// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    using SafeMathChainlink for uint256;

    enum LOTTERY_STATE { OPEN, CLOSED, CALCULATING_WINNER }
    LOTTERY_STATE public lotteryState;
    
    AggregatorV3Interface internal ethUsdPriceFeed;
    uint256 public usdEntryFee;
    address public recentWinner;
    address payable[] public players;
    uint256 public randomness;
    uint256 public fee;
    bytes32 public keyHash;
    
    event RequestedRandomness(bytes32 requestId);

    // Constructor for initializing VRF and price feed
    constructor(
        address _ethUsdPriceFeed, 
        address _vrfCoordinator, 
        address _link, 
        bytes32 _keyHash
    ) 
        VRFConsumerBase(
            _vrfCoordinator,
            _link
        ) 
        public 
    {
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        usdEntryFee = 50 * (10 ** 18);  // Entry fee in USD (scaled to 18 decimals)
        lotteryState = LOTTERY_STATE.CLOSED;
        fee = 100000000000000000; // 0.1 LINK
        keyHash = _keyHash;
    }

    // Function to enter the lottery
    function enter() public payable {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery is not open!");
        require(msg.value >= getEntranceFee(), "Not enough ETH to enter!");
        players.push(msg.sender);
    }

    // Get the ETH entrance fee based on current ETH/USD price
    function getEntranceFee() public view returns (uint256) {
        uint256 precision = 1 * 10 ** 18;
        uint256 price = getLatestEthUsdPrice(); // ETH price with 8 decimals
        uint256 costToEnter = (precision.mul(usdEntryFee)).div(price); // Adjusting based on USD fee
        return costToEnter;
    }

    // Fetch the latest ETH/USD price from Chainlink Price Feed
    function getLatestEthUsdPrice() public view returns (uint256) {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = ethUsdPriceFeed.latestRoundData();
        return uint256(price * 10**10); // Converting to 18 decimals
    }

    // Access control: Start the lottery
    function startLottery() public onlyOwner {
        require(lotteryState == LOTTERY_STATE.CLOSED, "Lottery already started");
        lotteryState = LOTTERY_STATE.OPEN;
        randomness = 0;
    }

    // Access control: End the lottery and initiate the randomness request
    function endLottery() public onlyOwner {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery is not open");
        lotteryState = LOTTERY_STATE.CALCULATING_WINNER;
        pickWinner();
    }

    // Function to request randomness from Chainlink VRF
    function pickWinner() private returns (bytes32) {
        require(lotteryState == LOTTERY_STATE.CALCULATING_WINNER, "Not ready to pick a winner");
        bytes32 requestId = requestRandomness(keyHash, fee);
        emit RequestedRandomness(requestId);
        return requestId;
    }

    // Callback function for Chainlink VRF with the randomness result
    function fulfillRandomness(bytes32 requestId, uint256 _randomness) internal override {
        require(_randomness > 0, "Random number not found");
        uint256 index = _randomness % players.length;
        players[index].transfer(address(this).balance);
        recentWinner = players[index];
        players = new address payable ;  // Reset players array
        lotteryState = LOTTERY_STATE.CLOSED;
        randomness = _randomness;  // Store the randomness
    }
}

/.Removed userProvidedSeed: The randomness request from Chainlink no longer requires a user-provided seed.
Randomness variable shadowing fixed: Renamed the argument in fulfillRandomness from randomness to _randomness to prevent overwriting the global variable.
Cost calculation adjustment: Updated getEntranceFee() to properly handle 18 decimals for precision and price.
Refined comments: Added clarifying comments to explain each function's purpose and logic../



