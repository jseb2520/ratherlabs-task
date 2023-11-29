// scripts/deploy.js
async function main() {
	const [deployer] = await ethers.getSigners();

	// Deploy Governance Token
	const GovernanceToken = await ethers.getContractFactory('GovernanceToken');
	const govToken = await GovernanceToken.deploy();
	await govToken.deployed();
	console.log('Governance Token deployed to:', govToken.address);

	// Deploy DAO contract with governance token address
	const DAO = await ethers.getContractFactory('DAO');
	const dao = await DAO.deploy(
		'0xYourVrfCoordinatorAddress',
		'0xYourLinkTokenAddress',
		'0xYourKeyHash',
		100, // Replace with your desired fee
		govToken.address // Pass governance token address as a parameter
	);
	await dao.deployed();
	console.log('DAO deployed to:', dao.address);
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
