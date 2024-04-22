Lottery System Smart Contract

Overview
This Ethereum smart contract implements a secure and transparent lottery system where participants can enter by sending a fixed amount of Ether. The contract uses Chainlink's Verifiable Random Function (VRF) to ensure a fair and secure process for selecting a winner, who then receives the entire pool of collected Ether, minus transaction fees. The contract includes features such as lottery start, stop, reset, and administrative controls accessible only by the contract owner.

Features
Participation: Users can enter the lottery by sending Ether matching a fixed entry fee.
Winner Selection: Utilizes Chainlink VRF to select a winner randomly, ensuring fairness.
Payout: The winner receives the entire pool of collected Ether securely.
Lottery Reset: Automatically resets after a winner is selected, allowing for new rounds without carrying over previous participants.
Administrative Controls: Functions to manage the lottery (start, stop, cancel) are restricted to the contract owner.
Smart Contract Functions
Public Functions
enterLottery(): Allows a user to enter the lottery by sending the correct entry fee.
startLottery(): Starts the lottery round, allowing entries.
stopLottery(): Stops the current lottery round, preventing further entries.
Owner-Only Functions
drawWinner(): Initiates the random selection of a winner.
withdrawLink(): Withdraws LINK tokens from the contract.
emergencyWithdraw(): Allows the owner to withdraw all Ether from the contract in case of emergency.
Events
LotteryEntry: Emitted when a user enters the lottery.
WinnerSelected: Emitted when a winner is selected.
LotteryStarted/Stopped: Emitted when the lottery is started or stopped.