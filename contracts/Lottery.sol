// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ReentrancyGuard for preventing reentrancy attacks.
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// Ownable for access control.
import "@openzeppelin/contracts/access/Ownable.sol";
// Chainlink's VRFConsumerBase for reliable randomness.
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

/**
 * Implements a secure lottery system with Chainlink VRF random number generation.
 * The contract uses the ReentrancyGuard to prevent reentrancy attacks, imports
 * Ownable for ownership management, and uses VRFConsumerBase for secure random number generation.
 */
contract Lottery is ReentrancyGuard, VRFConsumerBase, Ownable {
    uint256 public entryFee;
    address[] public participants;
    bool public lotteryActive;
    bytes32 internal keyHash;
    uint256 internal fee;
    bytes32 public lastRequestId;

    event LotteryEntry(address indexed participant);
    event WinnerSelected(address indexed winner, uint256 amount);
    event LotteryStarted();
    event LotteryStopped();
    event RandomnessRequested(bytes32 requestId);

    constructor(
        uint256 _entryFee,
        address vrfCoordinator,
        address linkToken,
        bytes32 _keyHash,
        uint256 _fee,
        address initialOwner  // Include an initialOwner parameter
    ) VRFConsumerBase(vrfCoordinator, linkToken)
      Ownable(initialOwner)  // Pass initialOwner to the Ownable constructor
    {
        require(_entryFee > 0, "Entry fee must be greater than 0");
        entryFee = _entryFee;
        lotteryActive = false;
        keyHash = _keyHash;
        fee = _fee;
    }

    // Participation

    /**
     * Enter the lottery. The function requires the lottery to be active and the
     * sent value to match the entry fee.
     */

    function enterLottery() public payable {
        require(lotteryActive, "Lottery is not active");
        require(msg.value == entryFee, "Incorrect entry fee");

        // Add the sender's address to the participants list.
        participants.push(msg.sender);

        // Log the entry event.
        emit LotteryEntry(msg.sender);
    }

    // Administrative Functions

    // Starts the lottery
    
    function startLottery() external onlyOwner {
        require(!lotteryActive, "Lottery already active");
        lotteryActive = true;
        emit LotteryStarted();
    }

    // Stops the lottery

    function stopLottery() external onlyOwner {
        require(lotteryActive, "Lottery not active");
        lotteryActive = false;
        emit LotteryStopped();
    }

    // Random Selection

    /**
     * @dev Request randomness from Chainlink VRF. Only the owner can call this function.
     * Requires the lottery to be active and have participants.
     */
    function drawWinner() external onlyOwner {
        require(lotteryActive, "Lottery is not active");
        require(participants.length > 0, "No participants in the lottery");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to pay fee");

        // Request randomness.
        lastRequestId = requestRandomness(keyHash, fee);

        // Log the randomness request event.
        emit RandomnessRequested(lastRequestId);
    }
    /**
     * Callback function used by VRF Coordinator. It's overriden to provide the logic
     * to handle randomness once it's available.
     * requestId is the ID of the randomness request.
     * randomness is the random number provided by Chainlink VRF.
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(lastRequestId == requestId, "Request ID does not match");

        // Select the winner using the random number.
        uint256 index = randomness % participants.length;
        address winner = participants[index];

        // Log the winner selection event.
        emit WinnerSelected(winner, address(this).balance);

        // Transfer the entire balance to the winner.
        (bool success, ) = payable(winner).call{value: address(this).balance}("");
        require(success, "Transfer failed");

        // Reset the lottery for the next round.
        resetLottery();
    }
    // Edge Cases and Reset

    /**
     * Function to reset the lottery state, clearing participants
     * and setting the lottery as inactive. This prepares the contract for the next round.
     */
    function resetLottery() internal {
    // Reset the participants array to an empty state
        participants = new address ;
    // Optionally reset other state variables as needed
        lotteryActive = false;
    }


    // Security

    /**
     * Receive function to prevent sending ETH directly to the contract address.
     */
    receive() external payable {
        revert("Please use the enterLottery function to participate.");
    }

    // Section: Administrative Functions - Withdrawal of funds and LINK

    /**
     * Allows the admin to withdraw LINK tokens from the contract. This is needed
     * in case we need to recover LINK after the lottery ends or for funding the VRF requests.
     */
    function withdrawLink() external onlyOwner {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }

    /**
     *  If in case the draw ends in a scenario where no valid participants are available
     * or any other unforeseen edge case, this ensures that the lottery owner can 
     * withdraw the contract balance. It's a security measure to handle any ETH trapped in 
     * the contract due to a failure.
     */
    function emergencyWithdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Emergency withdrawal failed");
    }

    // For Drawing

    /**
     * In the case of a draw, where the randomness provided by Chainlink VRF is 
     * unable to select a unique winner, this function can be called to attempt another draw.
     * It is a manual call by the admin to resolve the draw.
     */
    function resolveDraw() external onlyOwner {
        require(!lotteryActive, "Lottery must be inactive to resolve a draw");
        require(participants.length > 1, "Not enough participants to resolve a draw");

        // Requesting Chainlink for randomness again to resolve the draw.
        lastRequestId = requestRandomness(keyHash, fee);
        emit RandomnessRequested(lastRequestId);
    }
}
