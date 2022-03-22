const { expect } = require("chai");
const { ethers } = require("hardhat");

const coord1 = { x1: 0, y1: 0, x2: 3, y2: 3 };
const coord2 = { x1: 1, y1: 1, x2: 2, y2: 2 };
const coord3 = { x1: 5, y1: 5, x2: 7, y2: 7 };

describe("Voting contract", function () {
  
  it("TerrainMap func", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Voting = await ethers.getContractFactory("Voting");
    const voting = await Voting.deploy();
    await voting.deployed();

  //voteforTerrain func
    await voting.voteforTerrain(coord2);
    const voteCount = await voting.getVoters();
    expect(voteCount.length).to.equal(1);

  //endedVote func
    await voting.endedVote(0);
    const voteCount1 = await voting.getVoters();
    expect(voteCount1[0].state).to.equal(2);

  //terrainMap func
    await voting.terrainMap(voteCount1[0], addr1.address);
    const newMap = (await voting.connect(addr1).myMap()).plusCoordinator[0];
    expect(newMap.x1).to.equal(coord2.x1);
    expect(newMap.y2).to.equal(coord2.y2);
    //myMap func
      const ownerMap = (await voting.connect(owner).myMap()).minusCoordinator[0];
      const addr1Map = (await voting.connect(addr1).myMap()).plusCoordinator[0];
      expect(ownerMap.y1).to.equal(addr1Map.y1);  
  });

  it("Extending func", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Voting = await ethers.getContractFactory("Voting");
    const voting = await Voting.deploy();
    await voting.deployed();

  //voteforExtending func
    await voting.voteforExtending(coord3);
    const voteCount2 = await voting.getVoters();
    expect(voteCount2.length).to.equal(1);

  //extendingMap func
    await voting.extendingMap(voteCount2[voteCount2.length - 1], addr1.address);
    const extendingMap = (await voting.connect(addr1).myMap()).plusCoordinator[0];
    expect(extendingMap.x1).to.equal(coord3.x1);
    expect(extendingMap.x2).to.equal(coord3.x2);
  }); 
  
});
