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

    uint256 public votesToReject;

    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public votingRights;
    mapping(uint256 => mapping(address => bool)) public hasVotedForProposal;

    event ProposalCreated(
        uint256 indexed id,
        address indexed creator,
        string title,
        string optionA,
        string optionB
    );
    event Voted(uint256 indexed id, address indexed voter, string option);
    event ProposalApproved(
        uint256 indexed id,
        string title,
        string winningOption
    );
    event ProposalExecuted(
        uint256 indexed id,
        string title,
        string winningOption
    );
    event ProposalRejected(uint256 indexed id, string title);
    event ProposalCanceled(uint256 indexed id, string title);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier onlyVotingMember() {
        require(
            governanceToken.balanceOf(msg.sender) >= 1,
            "Not a voting member"
        );
        _;
    }

    constructor(IERC20 _governanceToken) {
        admin = msg.sender;
        governanceToken = _governanceToken;
    }

    struct Proposal {
        string title;
        string description;
        string optionA;
        string optionB;
        uint256 deadline;
        uint256 votesForOptionA;
        uint256 votesForOptionB;
        uint256 votesAgainst;
        uint256 votesToApprove;
        uint256 votesToExecute;
        uint256 votesToReject;
        address[] voters;
        bool executed;
        ProposalStatus status;
    }

    enum ProposalStatus {
        Pending,
        Approved,
        Rejected,
        Executed,
        Canceled
    }

    function createProposal(
        string memory _title,
        string memory _description,
        string memory _optionA,
        string memory _optionB,
        uint256 _duration
    ) external onlyVotingMember {
        proposalCount++;
        uint256 deadline = block.timestamp + _duration;

        proposals[proposalCount] = Proposal({
            title: _title,
            description: _description,
            optionA: _optionA,
            optionB: _optionB,
            deadline: deadline,
            votesForOptionA: 0,
            votesForOptionB: 0,
            votesAgainstProposal: 0,
            voters: new address[](0),
            executed: false,
            status: ProposalStatus.Pending
        });

        emit ProposalCreated(
            proposalCount,
            msg.sender,
            _title,
            _optionA,
            _optionB
        );
    }

    function vote(
        uint256 _proposalId,
        uint256 option
    ) external onlyVotingMember nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(
            proposal.status == ProposalStatus.Pending,
            "Proposal not pending"
        );
        require(block.timestamp < proposal.deadline, "Voting has ended");
        require(
            !hasVoted[_proposalId][msg.sender],
            "Already voted on this proposal"
        );
        require(
            governanceToken.balanceOf(msg.sender) >= 1,
            "Insufficient governance tokens"
        );
        require(option >= 1 && option <= 3, "Voted option not in range");

        hasVotedForProposal[_proposalId][msg.sender] = true;

        // Calculate the quadratic weight for the voter
        uint256 quadraticWeight = sqrt(governanceToken.balanceOf(msg.sender));

        votingRights[msg.sender] -= 1;
        string optionVoted;

        if (option == 1) {
            proposal.votesForOptionA += quadraticWeight;
            optionVoted = proposal.optionA;
        } else if (option == 2) {
            proposal.votesForOptionB += quadraticWeight;
            optionVoted = proposal.optionB;
        } else {
            proposal.votesAgainst += quadraticWeight;
            optionVoted = "Against";
        }


        
        // Add the voter to the array of voters
        proposal.voters.push(msg.sender);

        emit Voted(_proposalId, msg.sender, optionVoted);
    }

    function approveProposal(
        uint256 _proposalId,
        string memory _winningOption
    ) internal nonReentrant {
        Proposal memory proposal = proposals[_proposalId];
        require(
            !proposal.status == ProposalStatus.Approved,
            "Proposal already approved"
        );
        require(
            proposal.status == ProposalStatus.Pending,
            "Proposal not pending"
        );
        require(
            block.timestamp >= proposal.deadline,
            "Voting has not ended yet"
        );
        require(
            proposal.votesForOptionA + proposal.votesAgainst >=
                proposal.minVotes,
            "Not enough votes"
        );

        proposal.status = ProposalStatus.Approved;
        emit ProposalApproved(_proposalId, proposal.title, _winningOption);
    }

    function executeProposal(
        uint256 _proposalId,
        string _winninOption
    ) external onlyAdmin nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(
            proposal.status == ProposalStatus.Pending,
            "Proposal not pending"
        );
        require(
            block.timestamp >= proposal.deadline,
            "Voting has not ended yet"
        );
        require(
            proposal.votesForOptionA + proposal.votesAgainst >=
                proposal.minVotes,
            "Not enough votes"
        );

        proposal.executed = true;
        proposal.status = ProposalStatus.Executed;

        emit ProposalExecuted(_proposalId, proposal.title, decideAction(_proposalId, votesForOptionA, votesForOptionB, votesAgainst));
    }

    function rejectProposal(
        uint256 _proposalId,
        string _winninOption
    ) external onlyAdmin nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(
            proposal.status == ProposalStatus.Pending,
            "Proposal not pending"
        );
        require(
            proposal.votesAgainst >= proposal.votesToReject,
            "Not enough votes"
        );

        proposal.status = ProposalStatus.Rejected;

        emit ProposalRejected(_proposalId, proposal.title);
    }

    function cancelProposal(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        require(
            proposal.status == ProposalStatus.Pending,
            "Proposal not pending"
        );

        proposal.status = ProposalStatus.Canceled;

        // Refund voting rights to voters
        for (uint256 i = 0; i < proposal.voters.length; i++) {
            address voter = proposal.voters[i];
            votingRights[voter] += 1;
        }

        emit ProposalCanceled(_proposalId);
    }

    function hasVoted(
        Proposal storage _proposal,
        address _voter
    ) internal view returns (bool) {
        for (uint256 i = 0; i < _proposal.voters.length; i++) {
            if (_proposal.voters[i] == _voter) {
                return true;
            }
        }
        return false;
    }

    // Helper function to calculate the square root using Babylonian method
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    // Helper function to calculate percentages
    function calculatePercentages(
        uint256 totalVotes,
        uint256 input
    ) internal pure returns (uint256 percentage) {
        require(totalVotes > 0, "Total votes must be greater than zero");
        uint256 totalVotes = votesOptionA + votesOptionB + votesAgainst;

        // Calculate percentages using integer division
        percentage = (input * 100) / totalVotes;

        return (percentage);
    }
    // helper function to determine which action to apply for proposal depending of the amount of votes
    // as a global rule for the DAO, to mark a proposal as Approved or Rejected, votes for option A, B or Against should be at least 50% ot the total amount of votes
    function decideAction(uint256 _proposalId, uint256 totalVotesForOptionA, uint256 totalVotesForOptionB, uint256 totalVotesForOptionAgainst ) internal pure view returns (bool){
        Proposal storage proposal = proposals[_proposalId];
        require(totalVotesForOption > 0, "Total votes must be greater than zero");
        uint256 threshold = 50 * (totalVotesForOptionA + totalVotesForOptionB + totalVotesForOptionAgainst) / 100;
        if (totalVotesForOptionA >= threshold) {
            approveProposal(_proposalId, proposal.optionA);
        }
        if (proposal.votesForOptionA >= proposal.votesToApprove) {
            approveProposal(_proposalId, proposal.optionA);
        } else if (proposal.votesForOptionB >= votesToApprove) {
            approveProposal(_proposalId, proposal.optionB);
        } else if (proposal.votesAgainst >= votesToReject) {
            rejectProposal(_proposalId, proposal.title);
        }
    }
}
