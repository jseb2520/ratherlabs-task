// scripts/deployMockVRFCoordinator.js
const {ethers} = require('hardhat');

async function main() {
	const [deployer] = await ethers.getSigners();

	console.log('Deploying MockVRFCoordinator...');

	const MockVRFCoordinator = await ethers.getContractFactory(
		'MockVRFCoordinator'
	);
	const mockVRFCoordinator = await MockVRFCoordinator.deploy();
	await mockVRFCoordinator.deployed();

	console.log('MockVRFCoordinator deployed to:', mockVRFCoordinator.address);
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
