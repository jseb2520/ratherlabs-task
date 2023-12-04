const {ethers} = require('hardhat');

async function main() {
	const [admin] = await ethers.getSigners();

	// Replace this address with the address of the deployed DAO contract
	const daoAddress = 'DAOContractAddress';

	const DAO = await ethers.getContractFactory('DAO');
	const dao = await DAO.attach(daoAddress);

	// Proposal details
	const title = 'New Proposal';
	const description = 'Description of the new proposal';
	const duration = 7 * 24 * 60 * 60; // 7 days in seconds
	const minimumVotes = 10;
	const optionA = 'Option A';
	const optionB = 'Option B';

	try {
		// Create a new proposal
		await dao
			.connect(admin)
			.createProposal(
				title,
				description,
				duration,
				minimumVotes,
				optionA,
				optionB
			);

		console.log('Proposal created successfully.');
	} catch (error) {
		console.error('Error creating proposal:', error.message);
	}
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
