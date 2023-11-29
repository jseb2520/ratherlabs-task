// test/DAO.test.js
const {expect} = require('chai');

describe('DAO Contract', function () {
	let dao;
	let owner;

	// Mock values for constructor parameters
	const mockVrfCoordinator = '0xYourVrfCoordinatorAddress';
	const mockLink = '0xYourLinkTokenAddress';
	const mockKeyHash = '0xYourKeyHash';
	const mockFee = 100; // Replace with your desired fee

	beforeEach(async function () {
		// Deploy DAO contract with mock constructor parameters
		const DAO = await ethers.getContractFactory('DAO');
		[owner] = await ethers.getSigners();

		dao = await DAO.deploy(mockVrfCoordinator, mockLink, mockKeyHash, mockFee);
		await dao.deployed();
	});

	it('Should deploy DAO contract', async function () {
		// Test that the owner/admin is set correctly
		expect(await dao.owner()).to.equal(owner.address);
	});

	// Add more tests as needed
});
