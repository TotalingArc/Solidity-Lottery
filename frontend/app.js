// Import ABI and contract address
import lotteryAbi from './abi.json';

const contractAddress = 'YOUR_CONTRACT_ADDRESS';

// Connect to MetaMask and display account
let web3;
let lotteryContract;
let account;

async function connectWallet() {
  if (window.ethereum) {
    web3 = new Web3(window.ethereum);
    try {
      const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
      account = accounts[0];
      document.getElementById('accountDisplay').textContent = account;
      lotteryContract = new web3.eth.Contract(lotteryAbi, contractAddress);
      await loadLotteryData();
    } catch (error) {
      console.error('Error connecting wallet', error);
    }
  } else {
    alert('MetaMask not found. Please install it to continue.');
  }
}

document.getElementById('connectWallet').addEventListener('click', connectWallet);

// Load lottery data such as entrance fee
async function loadLotteryData() {
  const entranceFee = await lotteryContract.methods.getEntranceFee().call();
  document.getElementById('entranceFee').textContent = web3.utils.fromWei(entranceFee, 'ether');
}

// Enter lottery function
async function enterLottery() {
  const entranceFee = await lotteryContract.methods.getEntranceFee().call();
  try {
    await lotteryContract.methods.enter().send({
      from: account,
      value: entranceFee,
    });
    document.getElementById('status').textContent = 'Successfully entered the lottery!';
  } catch (error) {
    console.error('Error entering lottery', error);
    document.getElementById('status').textContent = 'Failed to enter lottery.';
  }
}

document.getElementById('enterLottery').addEventListener('click', enterLottery);

// Admin functions
async function startLottery() {
  try {
    await lotteryContract.methods.startLottery().send({ from: account });
    document.getElementById('status').textContent = 'Lottery started!';
  } catch (error) {
    console.error('Error starting lottery', error);
  }
}

async function endLottery() {
  try {
    await lotteryContract.methods.endLottery().send({ from: account });
    document.getElementById('status').textContent = 'Lottery ended! Calculating winner...';
  } catch (error) {
    console.error('Error ending lottery', error);
  }
}

document.getElementById('startLottery').addEventListener('click', startLottery);
document.getElementById('endLottery').addEventListener('click', endLottery);
