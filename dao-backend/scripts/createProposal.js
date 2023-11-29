const Web3 = require('web3');
const fs = require('fs');
const path = require('path');

// Set up the web3 provider (replace with your Ethereum node endpoint)
const web3 = new Web3('https://mainnet.infura.io/v3/YOUR_INFURA_API_KEY');

// Load the compiled DAO contract ABI from the contracts folder
const daoContractABIPath = path.resolve(
	__dirname,
	'../contracts/DAOContractABI.json'
);
const daoContractABI = JSON.parse(fs.readFileSync(daoContractABIPath, 'utf-8'));
const daoContractAddress = '0xYourDAOContractAddress'; // Replace with your DAO contract address

// Set the admin's private key (replace with the actual private key)
const adminPrivateKey = '0xYourAdminPrivateKey';

// Create a web3 account from the private key
const adminAccount = web3.eth.accounts.privateKeyToAccount(adminPrivateKey);
web3.eth.accounts.wallet.add(adminAccount);

// Create an instance of the DAO contract
const daoContract = new web3.eth.Contract(daoContractABI, daoContractAddress);

// Function to create a new proposal
async function createProposal(
	title = '',
	description = '',
	deadline = 0,
	minimumVotes = 0,
	optionA = '',
	optionB = ''
) {
	const proposalCount = await daoContract.methods.proposalCount().call();

	// Convert deadline to Unix timestamp
	const proposalDeadline = Math.floor(Date.now() / 1000) + parseInt(deadline);

	// Send the transaction to create a new proposal
	const tx = await daoContract.methods
		.createProposal(
			title,
			description,
			proposalDeadline,
			minimumVotes,
			optionA,
			optionB
		)
		.send({from: adminAccount.address, gas: 2000000});

	console.log(
		`Proposal created successfully. Proposal ID: ${proposalCount + 1}`
	);
}

// Example usage
createProposal(
	'First Proposal',
	'This is a sample proposal description.',
	604800, // 1 day (in seconds)
	10,
	'Option A',
	'Option B'
);
