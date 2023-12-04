const {expect, use} = require('chai');
const {ethers, upgrades} = require('hardhat');
const {solidity} = require('ethereum-waffle');

use(solidity);

describe('DAO Contract', function () {
	let GovernanceToken;
	let governanceToken;
	let DAO;
	let dao;
	let deployer;
	let voter1;
	let voter2;

	beforeEach(async function () {
		[deployer, voter1, voter2] = await ethers.getSigners();

		GovernanceToken = await ethers.getContractFactory('GovernanceToken');
		governanceToken = await GovernanceToken.deploy();

		await governanceToken.deployed();

		DAO = await ethers.getContractFactory('DAO');
		dao = await upgrades.deployProxy(DAO, [governanceToken.address, 10]);

		await dao.deployed();
	});

	it('Should create a new proposal', async function () {
		await governanceToken.mint(voter1.address, 10); // Mint tokens for voting
		await governanceToken.connect(voter1).approve(dao.address, 10);

		await dao.connect(voter1).createProposal(
			'New Proposal',
			'Description of the new proposal',
			7 * 24 * 60 * 60, // 7 days in seconds
			2,
			'Option A',
			'Option B'
		);

		const proposal = await dao.proposals(1);
		expect(proposal.title).to.equal('New Proposal');
		expect(proposal.status).to.equal(0); // 0 corresponds to ProposalStatus.Pending
	});

	it('Should vote in favor of a proposal', async function () {
		await governanceToken.mint(voter1.address, 10);
		await governanceToken.connect(voter1).approve(dao.address, 10);

		await dao.connect(voter1).createProposal(
			'New Proposal',
			'Description of the new proposal',
			7 * 24 * 60 * 60, // 7 days in seconds
			2,
			'Option A',
			'Option B'
		);

		await dao.connect(voter1).vote(1, true);

		const proposal = await dao.proposals(1);
		expect(proposal.votesForOptionA).to.equal(1);
		expect(proposal.status).to.equal(0); // ProposalStatus.Pending
	});

	it('Should vote against a proposal and cancel it', async function () {
		await governanceToken.mint(voter1.address, 10);
		await governanceToken.connect(voter1).approve(dao.address, 10);

		await dao.connect(voter1).createProposal(
			'New Proposal',
			'Description of the new proposal',
			7 * 24 * 60 * 60, // 7 days in seconds
			2,
			'Option A',
			'Option B'
		);

		await dao.connect(voter1).vote(1, false); // Voting against the proposal

		const proposal = await dao.proposals(1);
		expect(proposal.votesAgainst).to.equal(1);
		expect(proposal.status).to.equal(4); // ProposalStatus.Canceled
	});

	it('Should execute a proposal and trigger proposalApprovedAction', async function () {
		await governanceToken.mint(voter1.address, 10);
		await governanceToken.connect(voter1).approve(dao.address, 10);

		await dao.connect(voter1).createProposal(
			'New Proposal',
			'Description of the new proposal',
			7 * 24 * 60 * 60, // 7 days in seconds
			2,
			'Option A',
			'Option B'
		);

		await dao.connect(voter1).vote(1, true);

		// Wait for the voting period to end
		await ethers.provider.send('evm_increaseTime', [7 * 24 * 60 * 60 + 1]); // Increase time by 7 days and 1 second

		await dao.connect(deployer).executeProposal(1);

		const proposal = await dao.proposals(1);
		expect(proposal.status).to.equal(1); // ProposalStatus.Approved
	});

	it('Should reject a proposal without enough votes', async function () {
		await governanceToken.mint(voter1.address, 10);
		await governanceToken.connect(voter1).approve(dao.address, 10);

		await dao.connect(voter1).createProposal(
			'New Proposal',
			'Description of the new proposal',
			7 * 24 * 60 * 60, // 7 days in seconds
			2,
			'Option A',
			'Option B'
		);

		await dao.connect(voter1).vote(1, false); // Voting against the proposal

		// Wait for the voting period to end
		await ethers.provider.send('evm_increaseTime', [7 * 24 * 60 * 60 + 1]); // Increase time by 7 days and 1 second

		await dao.connect(deployer).executeProposal(1);

		const proposal = await dao.proposals(1);
		expect(proposal.status).to.equal(2); // ProposalStatus.Rejected
	});

	it('Should return active proposals', async function () {
		await governanceToken.mint(voter1.address, 10);
		await governanceToken.connect(voter1).approve(dao.address, 10);

		await dao.connect(voter1).createProposal(
			'New Proposal',
			'Description of the new proposal',
			7 * 24 * 60 * 60, // 7 days in seconds
			10,
			'Option A',
			'Option B'
		);

		await dao.connect(deployer).createProposal(
			'Another Proposal',
			'Description of another proposal',
			7 * 24 * 60 * 60, // 7 days in seconds
			5,
			'Option C',
			'Option D'
		);

		// Wait for 3 days
		await ethers.provider.send('evm_increaseTime', [3 * 24 * 60 * 60]);

		const activeProposals = await dao.getActiveProposals();

		expect(activeProposals.length).to.equal(2);
		expect(activeProposals[0].title).to.equal('New Proposal');
		expect(activeProposals[1].title).to.equal('Another Proposal');
	});
});
