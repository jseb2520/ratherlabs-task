// scripts/getCoordinatorAddressAndKeyHash.js
const {ethers} = require('hardhat');

async function main() {
	const [deployer] = await ethers.getSigners();

	// Replace with the actual address of the deployed MockVRFCoordinator
	const mockVRFCoordinatorAddress = '0xYourMockVRFCoordinatorAddress';

	// Get the key hash using a unique string (replace with your own string)
	const keyHash = await ethers.utils.solidityKeccak256(
		['string'],
		['your_unique_string']
	);

	console.log('MockVRFCoordinator Address:', mockVRFCoordinatorAddress);
	console.log('Key Hash:', keyHash);
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
