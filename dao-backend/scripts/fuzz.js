// scripts/fuzz.js
const hre = require('hardhat');
const {statefulFuzz} = require('hardhat-fuzzing');

async function main() {
	// Run the stateful fuzz test
	await statefulFuzz(hre);
}

// Run the fuzzing script
main();
