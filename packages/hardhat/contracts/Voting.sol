// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Ballot {
    struct Candidate {
        string name;
        uint256 voteCount;
    }

    enum ROLES {
        TEACHER,
        BOD,
        STUDENT
    }

    address[] voters;

    struct StatkeHolder {
        address identity;
        ROLES role;
    }

    address public chairman;

    uint256 winnerIndex;

    Candidate[] public candidates;
    StatkeHolder[] public statkeHolders;

    /**
     * @dev Create a new ballot to choose one of .
     *
     */
    constructor() {
        chairman = msg.sender;
    }

    function addCandidates(string[] memory cands) public onlyChairman {
        //check if candidate not included in the array
        for (uint256 i = 0; i < candidates.length; i++) {
            candidates.push(Candidate({name: cands[i], voteCount: 0}));
        }
    }

    function vote(uint256 candidateIndex) public onlyAuthorizedToVote {
        voters.push(msg.sender);
        candidates[candidateIndex].voteCount += 1;
    }

    function addStakeHolder(address id, ROLES role) public onlyChairman {
        statkeHolders.push(StatkeHolder({identity: id, role: role}));
    }

    function countVote() public teacherAndBod {
        uint256 winningVoteCount = 0;
        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winnerIndex = i;
            }
        }
    }

    function getWinner()
        public
        view
        onlyAuthorizedToVote
        returns (Candidate memory)
    {
        return candidates[winnerIndex];
    }

    modifier teacherAndBod() {
        uint256 stkhIndex;
        for (uint256 i = 0; i < statkeHolders.length; i++) {
            if (statkeHolders[i].identity == msg.sender) {
                stkhIndex = i;
                break;
            }
        }
        StatkeHolder storage stkh = statkeHolders[stkhIndex];
        require((msg.sender == chairman) || !(stkh.role == ROLES.STUDENT));
        _;
    }
    modifier onlyAuthorizedToVote() {
        bool stkhIndex;
        for (uint256 i = 0; i < statkeHolders.length; i++) {
            if (statkeHolders[i].identity == msg.sender) {
                stkhIndex = true;
                break;
            }
        }
        require((msg.sender == chairman) || (stkhIndex == true));
        _;
    }
    modifier onlyChairman() {
        require(msg.sender == chairman);
        _;
    }
}
