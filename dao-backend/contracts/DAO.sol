// contracts/DAO.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DAO is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public admin;
    IERC20 public governanceToken;

    uint256 public proposalCount;
    uint256 public minVotesToExecute;

    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public votingRights;

    event ProposalCreated(uint256 indexed id, address indexed creator, string title);
    event Voted(uint256 indexed id, address indexed voter, bool inFavor);
    event ProposalExecuted(uint256 indexed id, bool optionAWon);
    event ProposalCanceled(uint256 indexed id);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier onlyVotingMember() {
        require(votingRights[msg.sender] > 0, "Not a voting member");
        _;
    }

    constructor(IERC20 _governanceToken, uint256 _minVotesToExecute) {
        admin = msg.sender;
        governanceToken = _governanceToken;
        minVotesToExecute = _minVotesToExecute;
    }

    struct Proposal {
        string title;
        string description;
        uint256 deadline;
        uint256 minVotes;
        uint256 votesForOptionA;
        uint256 votesAgainst;
        address[] voters;
        bool executed;
        ProposalStatus status;
    }

    enum ProposalStatus { Pending, Approved, Rejected, Executed, Canceled }

    function createProposal(
        string memory _title,
        string memory _description,
        uint256 _duration,
        uint256 _minVotes,
        string memory _optionA,
        string memory _optionB
    ) external onlyAdmin {
        require(_minVotes > 0, "Minimum votes must be greater than 0");

        proposalCount++;
        uint256 deadline = block.timestamp + _duration;

        proposals[proposalCount] = Proposal({
            title: _title,
            description: _description,
            deadline: deadline,
            minVotes: _minVotes,
            votesForOptionA: 0,
            votesAgainst: 0,
            voters: new address[](0),
            executed: false,
            status: ProposalStatus.Pending
        });

        emit ProposalCreated(proposalCount, msg.sender, _title);
    }

    function vote(uint256 _proposalId, bool _inFavor) external onlyVotingMember nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal not pending");
        require(block.timestamp < proposal.deadline, "Voting has ended");

        // Ensure user has enough governance tokens to vote
        require(governanceToken.balanceOf(msg.sender) >= 1, "Insufficient governance tokens");

        // Ensure user has not already voted on the same proposal
        require(!hasVoted(proposal, msg.sender), "Already voted on this proposal");

        // Deduct 1 voting right from the user
        votingRights[msg.sender] -= 1;

        // Increment votes based on the vote direction
        if (_inFavor) {
            proposal.votesForOptionA += 1;
        } else {
            proposal.votesAgainst += 1;

            // Check if votes against exceed the threshold to cancel the proposal
            if (proposal.votesAgainst >= 30) {
                cancelProposal(_proposalId);
                return;
            }
        }

        // Add the voter to the array of voters
        proposal.voters.push(msg.sender);

        emit Voted(_proposalId, msg.sender, _inFavor);

        // Check if the proposal has enough votes to execute
        if (proposal.votesForOptionA + proposal.votesAgainst >= proposal.minVotes) {
            executeProposal(_proposalId);
        }
    }

    function executeProposal(uint256 _proposalId) public onlyAdmin nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal not pending");
        require(block.timestamp >= proposal.deadline, "Voting has not ended yet");

        proposal.executed = true;

        bool optionAWon = proposal.votesForOptionA > proposal.votesAgainst;
        proposal.status = optionAWon ? ProposalStatus.Approved : ProposalStatus.Rejected;

        // Perform actions when proposal option is approved
        if (proposal.status == ProposalStatus.Approved) {
            proposalApprovedAction(_proposalId, optionAWon);
        }

        emit ProposalExecuted(_proposalId, optionAWon);
    }

    function proposalApprovedAction(uint256 _proposalId, bool _optionAWon) internal {
        // Add your custom logic here
        // This function is called when a proposal's option is approved
        // You can perform any actions specific to your use case
        // For example, update state variables, interact with other contracts, etc.
    }

    function cancelProposal(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal not pending");

        proposal.status = ProposalStatus.Canceled;

        // Refund voting rights to voters
        for (uint256 i = 0; i < proposal.voters.length; i++) {
            address voter = proposal.voters[i];
            votingRights[voter] += 1;
        }

        emit ProposalCanceled(_proposalId);
    }

    function hasVoted(Proposal storage _proposal, address _voter) internal view returns (bool) {
        for (uint256 i = 0; i < _proposal.voters.length; i++) {
            if (_proposal.voters[i] == _voter) {
                return true;
            }
        }
        return false;
    }

}
