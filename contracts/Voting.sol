// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract Voting is Ownable{

  using SafeMath for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdTracker;

  struct Coordinator {
    uint256 x1;
    uint256 y1;
    uint256 x2;
    uint256 y2;
  }

  struct Map {
    address owner;
    Coordinator[] plusCoordinator;
    Coordinator[] minusCoordinator;
  }

  enum State { Created, Voting, Ended } // State of voting;

  struct Voter {
    uint256 index;
    State state;
    bool isVoted;
    Coordinator map;
  }

  Voter[] public voters;
  Map[] public maps;

  mapping (address => bool) public whiteListed;
  mapping (address => Voter) public ownerOfVoter;
  mapping (address => Map) private ownerOfMap;

  event CreatedVoteforTerrain(Voter indexed _voter);
  event CreatedVoteforExtending(Voter indexed _voter);
  event EndedVoter(Voter indexed _voter);
 

  modifier isMapOfOwner(Coordinator memory _coordinator) {
    Map memory map = ownerOfMap[msg.sender];
    Coordinator[] memory plusCoordinator =  map.plusCoordinator;
    Coordinator[] memory minusCoordinator =  map.minusCoordinator;
    for(uint i = 0; i < plusCoordinator.length; i++) {
      if(isIncludeCoordinator(plusCoordinator[i], _coordinator))
      { 
        if(minusCoordinator.length == 0 || !isIncludeCoordinator(minusCoordinator[i], _coordinator)) 
        {
           _;
        }
      }
    }
  }

  modifier CreatedState(Coordinator memory _coord) {
    bool isCreated = false;
    for (uint i = 0; i < voters.length; i++) {
      if (isIncludeCoordinator(voters[i].map, _coord)) {
        if (voters[i].state != State.Ended) {
          isCreated = true;
          break;     
        } else isCreated = false;
      }
      else if (!isIncludeCoordinator(voters[i].map, _coord)) {
        isCreated = false;
      }
    }
    if(!isCreated)
      _;
  }
    
  modifier VotingState(Voter memory _voter) {
    require(_voter.state == State.Created, "it must be in Voting Period");
    _;
    _voter.state = State.Ended;
  }
  
  modifier EndedState(Voter memory _voter) {
    require(_voter.state == State.Ended, "it must be in Ended Period");
    _;
  }

  modifier NonVoted(Voter memory _voter) {
    require(!_voter.isVoted, "it must be in Ended Period");
    _;
  }

  constructor() {
    Coordinator memory _coord = Coordinator(0,0,10,10);
    Map storage _map = ownerOfMap[owner()];
    _map.owner = owner();
    (_map.plusCoordinator).push(_coord);
    whiteListed[msg.sender] = true;
  }

  function isWhitedListed(address addr) public view returns (bool) {
    return whiteListed[addr];
  }

  // if _coord1 include _coord2, return true, else return false;
  function isIncludeCoordinator(Coordinator memory _coord1, Coordinator memory _coord2) private pure returns (bool) { 
    if( _coord1.x1 <= _coord2.x1 
        && _coord1.x2 >= _coord2.x2
        && _coord1.y1 <= _coord2.y1
        && _coord1.y2 >=_coord2.y2 )
      return true;
    else return false;
  }

  function voteforTerrain(Coordinator memory _coord) public isMapOfOwner(_coord) CreatedState(_coord) {
    _tokenIdTracker.increment();
    Voter memory voter;
    voter.map = _coord;
    voter.state = State.Created;
    voter.index = _tokenIdTracker.current();
    voter.isVoted = false;
    voters.push(voter);
    emit CreatedVoteforTerrain(voter);
  }

  function voteforExtending(Coordinator memory _coord) public onlyOwner CreatedState(_coord) {
    _tokenIdTracker.increment();
    Voter memory voter;
    voter.map = _coord;
    voter.state = State.Created;
    voter.index = _tokenIdTracker.current();
    voter.isVoted = false;
    voters.push(voter);
    emit CreatedVoteforExtending(voter);
  }

  function endedVote(uint256 index) public VotingState(voters[index]) {
    require(ownerOfVoter[msg.sender].index == index, "only vote onwer");
    Voter storage voter = voters[index];
    voter.state = State.Ended;  
    emit EndedVoter(voter);
  }

  function terrainMap(Voter memory _voter, address _address) external isMapOfOwner(_voter.map)  EndedState(_voter) NonVoted(_voter) {
    Map storage _map = ownerOfMap[_address];
    _map.owner = _address;
    _map.plusCoordinator.push(_voter.map);
    ownerOfMap[msg.sender].minusCoordinator.push(_voter.map);
    _voter.isVoted = true;
  }

  function extendingMap(Voter memory _voter, address _address) external onlyOwner isMapOfOwner(_voter.map) {
    Map storage _map = ownerOfMap[_address];
    _map.owner = _address;
    (_map.plusCoordinator).push(_voter.map);
    (ownerOfMap[msg.sender].minusCoordinator).push(_voter.map);
    _voter.isVoted = true;
  }

  function myMap() external view returns (Map memory _maps) {
    _maps = ownerOfMap[msg.sender];
    return _maps;
  }

  function getVoters() external view returns(Voter[] memory _voters) {
      _voters = voters;
      return _voters;
  }
}