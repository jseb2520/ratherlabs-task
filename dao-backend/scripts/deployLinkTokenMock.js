// scripts/deployLinkTokenMock.js
const {ethers} = require('hardhat');

async function main() {
	const [deployer] = await ethers.getSigners();

	console.log('Deploying LINK Token Mock...');

	const LinkTokenMock = await ethers.getContractFactory('LinkTokenMock');
	const linkTokenMock = await LinkTokenMock.deploy();
	await linkTokenMock.deployed();

	console.log('LINK Token Mock deployed to:', linkTokenMock.address);
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
