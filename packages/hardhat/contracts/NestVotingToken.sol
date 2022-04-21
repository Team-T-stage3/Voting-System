// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract NestVotingToken is ERC20, Pausable, AccessControl {
    bytes32 public constant CHAIRMAN = keccak256("CHAIRMAN");
    bytes32 public constant MEMBER = keccak256("MEMBER");
    bytes32 public constant BOARD = keccak256("BOARD");
    bytes32 public constant BANK = keccak256("BANK");
    bytes32 public constant TEACHER = keccak256("TEACHER");
    bytes32 public constant STUDENT = keccak256("STUDENT");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");


    address private bank;   

    address public chairman; 
    constructor() ERC20("NestVotingToken", "NVT") {
        
        grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(PAUSER_ROLE, msg.sender);
        grantRole(MINTER_ROLE, msg.sender);
        grantRole(CHAIRMAN, msg.sender);
        grantRole(MEMBER, msg.sender);
        grantRole(BOARD, msg.sender);
        chairman = msg.sender;
         _mint(msg.sender, 5000 * 10 ** decimals());
    }

    event VoteCasted(address voter, uint256 pollID, string vote);
	event PollCreation(uint256 pollID, string description, uint256 numOfCategories);
	event PollStatusUpdate(uint256 pollID, PollStatus status);


	enum PollStatus { IN_PROGRESS, DISABLED, RESULTSHOWED }

    struct Poll
	{
		string description;
		PollStatus status;
        mapping(string => uint256) voteCounts;
		mapping(address => Voter) voterInfo;
        string[] candidates;
        uint256[] percents; 
	}

	struct Voter
	{
		bool hasVoted;
		string vote;
	}

    uint256 public pollCount;
	mapping(uint256 => Poll) public polls;
    mapping(address => bool) public teachers;
    mapping(address => bool) public students;
    mapping(address => bool) public board;

    function createPoll(string memory _description, string[] memory _categories) external onlyRole(CHAIRMAN) returns (uint256)
	{
		pollCount++;
		Poll storage curPoll = polls[pollCount];
		curPoll.status = PollStatus.IN_PROGRESS;
		curPoll.description = _description;
        curPoll.candidates = _categories;

        for(uint i = 0; i < _categories.length; i++) {
            curPoll.voteCounts[_categories[i]] = 0;
        }

		emit PollCreation(pollCount, curPoll.description, _categories.length);
		return pollCount;
	}


  function addTeachers(address[] memory _teachers) external onlyRole(BOARD) {
    for(uint i = 0; i < _teachers.length; i++) {
        teachers[_teachers[i]] = true;
        _mint(_teachers[i], 3000 * 10 ** decimals());
        grantRole(TEACHER, _teachers[i]);
        grantRole(MEMBER, _teachers[i]);
    }
  }

  function addBank(address _bank) external onlyRole(CHAIRMAN) {
        bank = _bank;
        grantRole(BANK, _bank);
    
  }

  function addStudents(address[] memory _students) external onlyRole(BOARD) {
    for(uint i = 0; i < _students.length; i++) {
        students[_students[i]] = true;
        _mint(_students[i], 1000 * 10 ** decimals());
        grantRole(STUDENT, _students[i]);
        grantRole(MEMBER, _students[i]);
    }
  }

  function addBoards(address[] memory _boards) external onlyRole(CHAIRMAN) {
    for(uint i = 0; i < _boards.length; i++) {
        board[_boards[i]] = true;
        _mint(_boards[i], 4000 * 10 ** decimals());
        grantRole(BOARD, _boards[i]);
        grantRole(MEMBER, _boards[i]);
    }
  }

    function getPollStatus(uint256 _pollID) public view validPoll(_pollID) returns (PollStatus)
	{
		return polls[_pollID].status;
	}

    function castVote(uint256 _pollID, string memory _vote) external
     validPoll(_pollID) onlyRole(MEMBER) notDisabled(_pollID)
	{
		require(polls[_pollID].status == PollStatus.IN_PROGRESS, "Poll not in progress.");
		require(polls[_pollID].voterInfo[msg.sender].hasVoted, "User has already voted.");

		transferFrom(msg.sender, bank, 100);

		Poll storage curPoll = polls[_pollID];

		curPoll.voterInfo[msg.sender] = Voter({
				hasVoted: true,
				vote: _vote
		});

        curPoll.voteCounts[_vote] += 1;

		emit VoteCasted(msg.sender, _pollID, _vote);
	}


    function compileVotes(uint256 _pollID)  public   onlyChairmanOrTeacher notDisabled(_pollID) {
        Poll storage curPoll = polls[_pollID];

        string[] memory candidates = curPoll.candidates;
        uint256[] memory percents;
        uint totalVotes = candidates.length;
    
        for (uint i = 0; i < totalVotes; i++) {
            percents[i] = curPoll.voteCounts[candidates[i]] * 10000 / totalVotes;
            
        }

        curPoll.percents = percents;
    }

        function showResults(uint256 _pollID) public view notStudent notDisabled(_pollID) returns (string[] memory, uint256[] memory){
            Poll storage curPoll = polls[_pollID];

            return (curPoll.candidates, curPoll.percents);
        }

        

        function diablePoll(uint256 _pollID) public onlyRole(CHAIRMAN) {

            Poll storage curPoll = polls[_pollID];

            if(curPoll.status == PollStatus.IN_PROGRESS){
                curPoll.status = PollStatus.DISABLED;
                emit PollStatusUpdate( _pollID, curPoll.status);
                pause();
            }else{
                curPoll.status = PollStatus.IN_PROGRESS;
                emit PollStatusUpdate( _pollID, curPoll.status);
                unpause();
            }

        }

    modifier onlyChairmanOrTeacher() {
        require(
            hasRole(CHAIRMAN, msg.sender) || hasRole(TEACHER, msg.sender),
            
            "Not a Chairman nor a Teacher."
        );
        _;
    }

    modifier notStudent() {
        require(
            hasRole(CHAIRMAN, msg.sender) || hasRole(TEACHER, msg.sender) || hasRole(TEACHER, msg.sender),
            
            "You are a Student."
        );
        _;
    }

    modifier validPoll(uint256 _pollID)
	{
		require(_pollID > 0 && _pollID <= pollCount, "Not a valid poll Id.");
		_;
	}

    modifier notDisabled(uint256 _pollID)
	{
        Poll storage curPoll = polls[_pollID];
		require(curPoll.status != PollStatus.DISABLED, "Poll is Disabled");
		_;
	}

    function pause() public {
        _pause();
    }

    function unpause() public  {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(CHAIRMAN) {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    
}
