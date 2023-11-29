// contracts/DAO.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@chainlink/contracts/VRF/VRFConsumerBase.sol";

contract DAO is VRFConsumerBase, ERC20Votes {
    using SafeERC20 for IERC20;

    address public admin;
    address public vrfCoordinator;
    bytes32 public keyHash;
    uint256 public fee;
    uint256 public proposalCount;

    mapping(address => uint256) public votingRights;
    mapping(uint256 => Proposal) public proposals;

    enum ProposalStatus { Pending, Approved, Rejected, Executed }

    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 deadline;
        uint256 minimumVotes;
        uint256 votesForOptionA;
        uint256 votesForOptionB;
        ProposalStatus status;
        bool executed;
    }

    event ProposalCreated(uint256 indexed id, address indexed proposer, string title);
    event Voted(uint256 indexed proposalId, address indexed voter, bool supportsOptionA);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier onlyVotingMember() {
        require(votingRights[msg.sender] > 0, "Not a voting member");
        _;
    }

    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee,
        address _governanceToken
    )
        VRFConsumerBase(_vrfCoordinator, _link)
        ERC20("Governance Token", "GOV")
    {
        admin = msg.sender;
        vrfCoordinator = _vrfCoordinator;
        keyHash = _keyHash;
        fee = _fee;

        // Mint initial governance tokens to the admin
        _mint(msg.sender, 1000000 * 10**decimals());
        votingRights[msg.sender] = balanceOf(msg.sender);
    }

    function createProposal(
        string memory _title,
        string memory _description,
        uint256 _duration,
        uint256 _minimumVotes
    )
        external
        onlyVotingMember
    {
        proposalCount++;

        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.deadline = block.timestamp + _duration;
        newProposal.minimumVotes = _minimumVotes;
        newProposal.status = ProposalStatus.Pending;

        emit ProposalCreated(proposalCount, msg.sender, _title);
    }

    function vote(uint256 _proposalId, bool _supportsOptionA) external onlyVotingMember {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal not pending");
        require(block.timestamp < proposal.deadline, "Voting has ended");

        // Voting weight is the number of governance tokens held by the voter
        uint256 votingWeight = votingRights[msg.sender];
        require(votingWeight > 0, "No voting rights");

        if (_supportsOptionA) {
            proposal.votesForOptionA += votingWeight;
        } else {
            proposal.votesForOptionB += votingWeight;
        }

        emit Voted(_proposalId, msg.sender, _supportsOptionA);

        // Check if the proposal has reached the minimum votes required
        if (proposal.votesForOptionA + proposal.votesForOptionB >= proposal.minimumVotes) {
            executeProposal(_proposalId);
        }
    }

    function executeProposal(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal not pending");
        require(block.timestamp >= proposal.deadline, "Voting is still ongoing");

        // Check if Option A has more votes than Option B
        if (proposal.votesForOptionA > proposal.votesForOptionB) {
            // Execute the proposal (you can add your own logic here)
            proposal.status = ProposalStatus.Approved;
            proposal.executed = true;
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
    }

    function requestRandomness() external onlyAdmin {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // Implement your logic here with the obtained randomness
        // For example, you can use it to determine the outcome of proposals
        // Note: Make sure to handle the obtained randomness securely
    }

    // Admin functions to manage voting rights

    function grantVotingRights(address _voter, uint256 _amount) external onlyAdmin {
        _mint(_voter, _amount);
        votingRights[_voter] += _amount;
    }

    function revokeVotingRights(address _voter, uint256 _amount) external onlyAdmin {
        _burn(_voter, _amount);
        votingRights[_voter] -= _amount;
    }

    // Withdraw LINK tokens accidentally sent to this contract
    function withdrawLink() external onlyAdmin {
        LINK.transfer(admin, LINK.balanceOf(address(this)));
    }
}
