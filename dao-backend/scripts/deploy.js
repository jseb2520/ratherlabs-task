// scripts/deploy.js
const {ethers, upgrades} = require('hardhat');

async function main() {
	const GovernanceToken = await ethers.getContractFactory('GovernanceToken'); // Assuming you have a GovernanceToken contract
	const governanceToken = await GovernanceToken.deploy();

	await governanceToken.deployed();

	console.log('Governance Token deployed to:', governanceToken.address);

	const DAO = await ethers.getContractFactory('DAO');
	const dao = await upgrades.deployProxy(DAO, [governanceToken.address, 10]); // Adjust 10 to your desired minVotesToExecute

	await dao.deployed();

	console.log('DAO deployed to:', dao.address);
}

main();
