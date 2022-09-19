import { assert, expect } from "chai";
import { BigNumber } from "ethers";
import {
  RepublicChancelor,
  RepublicChancelor__factory,
  RepublicExecutor,
  RepublicExecutor__factory,
  Token1,
  Token1__factory,
  Token2,
  Token2__factory,
} from "../typechain-types";
import Web3 from "web3";
import deployToken1 from "../deploy/01-deploy-token1";
import deployExecutor from "../deploy/04-deploy-republicExecutor";
import deployChancelor from "../deploy/05-deploy-republicChancelor";
import { chainMine, chainSleep, getAccount } from "../scripts/utils";
import { ProposalCreatedEvent } from "../typechain-types/contracts/ChancelorUpgradeable";
import { ProposalQueuedEvent } from "../typechain-types/contracts/compatibility/ChancelorCompatibilityBravoUpgradeable";
import deployToken2 from "../deploy/02-deploy-token2";
import { network } from "hardhat";

const hre = require("hardhat");
describe("LilyPad", function () {
  const { deployments, getNamedAccounts, web3, ethers } = require("hardhat");
  const { get } = deployments;

  let _token1Contract: Token1;
  let _token2Contract: Token2;
  let _republicExecutorContract: RepublicExecutor;
  let _republicChancelorContract: RepublicChancelor;
  beforeEach(async function () {
    await deployToken1(hre);
    await deployToken2(hre);
    await deployExecutor(hre);
    await deployChancelor(hre);

    const token1Factory: Token1__factory = await ethers.getContractFactory(
      "Token1"
    );
    const _token1 = await get("Token1");

    _token1Contract = await token1Factory.attach(_token1.address);

    const token2Factory: Token2__factory = await ethers.getContractFactory(
      "Token2"
    );
    const _token2 = await get("Token2");

    _token2Contract = await token2Factory.attach(_token2.address);

    const executorFactory: RepublicExecutor__factory =
      await ethers.getContractFactory("RepublicExecutor");
    const _executor = await get("RepublicExecutor");

    _republicExecutorContract = await executorFactory.attach(_executor.address);

    const chancelorFactory: RepublicChancelor__factory =
      await ethers.getContractFactory("RepublicChancelor");
    const _chancelor = await get("RepublicChancelor");

    _republicChancelorContract = await chancelorFactory.attach(
      _chancelor.address
    );

    assert(_token1Contract, "Could not deploy token contract");
    assert(_republicExecutorContract, "Could not deploy executor contract");
    assert(_republicChancelorContract, "Could not deploy chancelor contract");
  });
  describe("DaoTest", function () {
    it("Try to create a proposal and vote. It should work with no problems", async function () {
      const { deployer, safeCaller } = await getNamedAccounts();
      const _web3: Web3 = web3;
      const _minters = await getAccount("minters", 10);

      const executorMinDelay = 272;
      const quorum = 25; //percentage
      const votingPeriod = 500; //~110 minutes in blocks
      const votingDelay = 30; //~7 minutes in blocks

      for (const minter of _minters) {
        const mintTx = await _token1Contract.safeMint(minter.address);
        await mintTx.wait(1);

        console.log(
          `Minter ${
            minter.address
          } balance (Token 1): ${await _token1Contract.balanceOf(
            minter.address
          )} Votes: ${await _token1Contract.getVotes(minter.address)}`
        );

        const mintTx2 = await _token2Contract.safeMint(minter.address);
        await mintTx2.wait(1);

        console.log(
          `Minter ${
            minter.address
          } balance (Token 2): ${await _token2Contract.balanceOf(
            minter.address
          )} Votes: ${await _token2Contract.getVotes(minter.address)}`
        );

        assert(
          (await _token1Contract.balanceOf(minter.address)).eq(1),
          "Token not minted :-("
        );
        assert(
          (await _token1Contract.getVotes(minter.address)).gt(0),
          "Didnt get votes :-("
        );
        assert(
          (await _token2Contract.balanceOf(minter.address)).eq(1),
          "Token 2 not minted :-("
        );
        assert(
          (await _token2Contract.getVotes(minter.address)).gt(0),
          "Didnt get votes token 2 :-("
        );
      }

      //proposal
      const PROPOSAL_DESCRIPTION =
        "bafkreicwrdofqb56rkspleeo3deyxpl4ku23bncxrsozfh6mr7pgsmjkge";
      const args = [2];

      const factory = await ethers.getContractFactory("RepublicChancelor");
      const PROPOSAL_FUNCTION = factory.interface.encodeFunctionData(
        "setProposalThreshold",
        args
      );

      //propose
      const propId = await propose(
        [_republicChancelorContract.address],
        [0],
        [PROPOSAL_FUNCTION],
        _minters[0],
        PROPOSAL_DESCRIPTION,
        _republicChancelorContract!!
      );

      console.log(
        `Proposal snapshot ${await _republicChancelorContract.proposalSnapshot(
          propId!!
        )}`
      );
      console.log(
        `Proposal deadline ${await _republicChancelorContract.proposalDeadline(
          propId!!
        )}`
      );
      console.log(
        `Proposal State: ${
          proposalStatesEnum[await _republicChancelorContract.state(propId!!)]
        }`
      );

      //mine voting delay
      console.log("Mint blocks for voting delay and try to vote...");
      await chainMine(votingDelay + 1);

      console.log(
        `Proposal Quorum: ${await _republicChancelorContract.quorum(
          await _republicChancelorContract.proposalSnapshot(propId!!)
        )}`
      );

      for (const minter of _minters) {
        let voteOpt = 1;
        let voteDesc = "is in favor";

        const minterVotingPower = Number(
          await _republicChancelorContract.getVotes(
            minter.address,
            await _republicChancelorContract.proposalSnapshot(propId!!)
          )
        );

        console.log(`Minter Voting Power: ${minterVotingPower}`);

        let voteResult = await vote(
          minter,
          propId,
          voteOpt,
          "",
          _republicChancelorContract
        );

        console.log(`Voter ${minter.address} voted ${voteDesc}`);
      }
      const {
        id,
        proposer,
        eta,
        startBlock,
        endBlock,
        forVotes,
        againstVotes,
        abstainVotes,
        canceled,
        executed,
      } = await _republicChancelorContract.proposals(propId);

      console.log(`In Favor: ${forVotes}`);
      console.log(`Against: ${againstVotes}`);
      console.log(`Abstained: ${abstainVotes}`);
      console.log(`startBlock: ${startBlock}`);
      console.log(`endBlock: ${endBlock}`);

      //mine voting period and try to vote
      await chainMine(votingPeriod);

      console.log(
        `Proposal State: ${
          proposalStatesEnum[await _republicChancelorContract.state(propId!!)]
        }`
      );

      console.log(
        `Quorum Reached: ${await _republicChancelorContract.quorumReached(
          propId!!
        )}`
      );

      const schedulePropId = await queue(
        _minters[0],
        [_republicChancelorContract.address],
        [0],
        [PROPOSAL_FUNCTION],
        PROPOSAL_DESCRIPTION,
        _republicChancelorContract!!
      );

      console.log(
        `Proposal State: ${
          proposalStatesEnum[await _republicChancelorContract.state(propId!!)]
        }`
      );

      await chainSleep(executorMinDelay + 1);
      await chainMine(1);

      //check if proposalThreshold was changed
      console.log(
        `Old proposal Threshold: ${_republicChancelorContract.proposalThreshold()}`
      );

      await execute(
        _minters[0],
        [_republicChancelorContract.address],
        [0],
        [PROPOSAL_FUNCTION],
        PROPOSAL_DESCRIPTION,
        _republicChancelorContract!!
      );

      console.log(
        `Proposal State: ${
          proposalStatesEnum[await _republicChancelorContract.state(propId!!)]
        }`
      );

      //check if proposalThreshold was changed
      console.log(
        `New proposal Threshold: ${await _republicChancelorContract.proposalThreshold()}`
      );
    });
    it("Try to create a proposal and vote, but not reaching quorum. It should revert when trying to queue proposal", async function () {
      const { deployer, safeCaller } = await getNamedAccounts();
      const _web3: Web3 = web3;
      const _minters = await getAccount("minters", 10);

      const executorMinDelay = 272;
      const quorum = 25; //percentage
      const votingPeriod = 500; //~110 minutes in blocks
      const votingDelay = 30; //~7 minutes in blocks

      for (const minter of _minters) {
        const mintTx = await _token1Contract.safeMint(minter.address);
        await mintTx.wait(1);

        console.log(
          `Minter ${
            minter.address
          } balance (Token 1): ${await _token1Contract.balanceOf(
            minter.address
          )} Votes: ${await _token1Contract.getVotes(minter.address)}`
        );

        const mintTx2 = await _token2Contract.safeMint(minter.address);
        await mintTx2.wait(1);

        console.log(
          `Minter ${
            minter.address
          } balance (Token 2): ${await _token2Contract.balanceOf(
            minter.address
          )} Votes: ${await _token2Contract.getVotes(minter.address)}`
        );

        assert(
          (await _token1Contract.balanceOf(minter.address)).eq(1),
          "Token not minted :-("
        );
        assert(
          (await _token1Contract.getVotes(minter.address)).gt(0),
          "Didnt get votes :-("
        );
        assert(
          (await _token2Contract.balanceOf(minter.address)).eq(1),
          "Token 2 not minted :-("
        );
        assert(
          (await _token2Contract.getVotes(minter.address)).gt(0),
          "Didnt get votes token 2 :-("
        );
      }

      //proposal
      const PROPOSAL_DESCRIPTION =
        "bafkreicwrdofqb56rkspleeo3deyxpl4ku23bncxrsozfh6mr7pgsmjkge";
      const args = [2];

      const factory = await ethers.getContractFactory("RepublicChancelor");
      const PROPOSAL_FUNCTION = factory.interface.encodeFunctionData(
        "setProposalThreshold",
        args
      );

      //propose
      const propId = await propose(
        [_republicChancelorContract.address],
        [0],
        [PROPOSAL_FUNCTION],
        _minters[0],
        PROPOSAL_DESCRIPTION,
        _republicChancelorContract!!
      );

      console.log(
        `Proposal snapshot ${await _republicChancelorContract.proposalSnapshot(
          propId!!
        )}`
      );
      console.log(
        `Proposal deadline ${await _republicChancelorContract.proposalDeadline(
          propId!!
        )}`
      );
      console.log(
        `Proposal State: ${
          proposalStatesEnum[await _republicChancelorContract.state(propId!!)]
        }`
      );

      //mine voting delay
      console.log("Mint blocks for voting delay and try to vote...");
      await chainMine(votingDelay + 1);

      console.log(
        `Proposal Quorum: ${await _republicChancelorContract.quorum(
          await _republicChancelorContract.proposalSnapshot(propId!!)
        )}`
      );

      let voteOpt = 1;
      let voteDesc = "is in favor";

      //const minterVotingPower = Number(
      //  await _token1Contract.getPastVotes(
      //    minter.address,
      //    await _republicChancelorContract.proposalSnapshot(propId!!)
      //  )
      //);
      const minterVotingPower = Number(
        await _republicChancelorContract.getVotes(
          _minters[0].address,
          await _republicChancelorContract.proposalSnapshot(propId!!)
        )
      );

      console.log(`Minter Voting Power: ${minterVotingPower}`);

      let voteResult = await vote(
        _minters[0],
        propId,
        voteOpt,
        "",
        _republicChancelorContract
      );

      console.log(`Voter ${_minters[0].address} voted ${voteDesc}`);

      const {
        id,
        proposer,
        eta,
        startBlock,
        endBlock,
        forVotes,
        againstVotes,
        abstainVotes,
        canceled,
        executed,
      } = await _republicChancelorContract.proposals(propId);

      console.log(`In Favor: ${forVotes}`);
      console.log(`Against: ${againstVotes}`);
      console.log(`Abstained: ${abstainVotes}`);

      //mine voting period and try to queue
      await chainMine(votingPeriod + 1);

      console.log(
        `Proposal State: ${
          proposalStatesEnum[await _republicChancelorContract.state(propId!!)]
        }`
      );

      console.log(
        `Quorum Reached: ${await _republicChancelorContract.quorumReached(
          propId!!
        )}`
      );

      const schedulePropId = await queue(
        _minters[0],
        [_republicChancelorContract.address],
        [0],
        [PROPOSAL_FUNCTION],
        PROPOSAL_DESCRIPTION,
        _republicChancelorContract!!
      );

      console.log(
        `Proposal State: ${
          proposalStatesEnum[await _republicChancelorContract.state(propId!!)]
        }`
      );

      await chainSleep(executorMinDelay + 1);
      await chainMine(1);
    });
  });

  async function propose(
    contractAddr: string[],
    values: any[],
    functionData: any[],
    proposer: any,
    proposalDescription: string,
    republicChancelor: RepublicChancelor
  ): Promise<BigNumber> {
    const account = await getAccount("owner");

    republicChancelor = await republicChancelor.connect(proposer);

    const proposalTx = await republicChancelor[
      "propose(address[],uint256[],bytes[],string)"
    ](contractAddr, values, functionData, proposalDescription);

    const receipt = await proposalTx.wait(1);
    let propId: BigNumber;
    for (const ev of receipt!!.events!!) {
      if (ev.event == "ProposalCreated") {
        propId = (ev as ProposalCreatedEvent).args.proposalId;
        console.log(`Proposal Id: ${propId}`);
      }
    }

    console.log(
      `Proposal snapshot ${await republicChancelor.proposalSnapshot(propId!!)}`
    );
    console.log(
      `Proposal deadline ${await republicChancelor.proposalDeadline(propId!!)}`
    );
    console.log(
      `Proposal State: ${
        proposalStatesEnum[await republicChancelor.state(propId!!)]
      }`
    );
    return propId!!;
  }

  async function vote(
    _from: any,
    proposal_id: BigNumber,
    vote: number,
    reason: String,
    republicChancelor: RepublicChancelor
  ): Promise<boolean> {
    let voteDesc = "IN FAVOR";

    if (vote == 0) voteDesc = "AGAINST";
    else if (vote == 2) voteDesc = "ABSTAIN";
    //0 = Against, 1 = For, 2 = Abstain for this example
    //you can all the #COUNTING_MODE() function to see how to vote otherwise
    console.log(`${_from.address} voting ${voteDesc} on ${proposal_id}`);
    republicChancelor = await republicChancelor.connect(_from);
    try {
      if (reason) {
        const tx = await republicChancelor.castVoteWithReason(
          proposal_id,
          vote,
          reason.toString()
        );
        await tx.wait(1);
      } else {
        const tx = await republicChancelor.castVote(proposal_id, vote);
        const receipt = await tx.wait(1);
        //console.log(receipt.events)
      }
    } catch (err: any) {
      console.error(err.message);
      return false;
    }

    return true;
  }

  async function queue(
    _from: any,
    contractAddress: string[],
    values: any[],
    functionData: any[],
    proposalDescription: string,
    republicChancelor: RepublicChancelor
  ): Promise<BigNumber> {
    const description_hash = ethers.utils.id(proposalDescription); //web3.utils.keccak256(proposalDescription)
    console.log(description_hash);
    let scheduleId: BigNumber;
    try {
      console.log(`from Account: ${_from.address}`);
      republicChancelor = await republicChancelor.connect(_from);

      const tx = await republicChancelor[
        "queue(address[],uint256[],bytes[],bytes32)"
      ](contractAddress, values, functionData, description_hash);
      const receipt = await tx.wait(1);
      for (const ev of receipt!!.events!!) {
        if (ev.event == "ProposalQueued") {
          scheduleId = (ev as ProposalQueuedEvent).args.proposalId;
          console.log(`Proposal Schedule Id: ${scheduleId}`);
        }
      }
      return scheduleId!!;
    } catch (err: any) {
      console.log(err.message);
      return BigNumber.from("0");
    }
  }

  async function execute(
    _from: any,
    contractAddress: string[],
    values: any[],
    functionData: any[],
    proposalDescription: string,
    republicChancelor: RepublicChancelor
  ) {
    const description_hash = ethers.utils.id(proposalDescription);
    republicChancelor = await republicChancelor.connect(_from);

    try {
      const tx = await republicChancelor[
        "execute(address[],uint256[],bytes[],bytes32)"
      ](contractAddress, values, functionData, description_hash);
      tx.wait(1);
    } catch (err: any) {
      console.log(err.message);
    }
  }

  enum proposalStatesEnum {
    Pending = 0,
    Active = 1,
    Canceled = 2,
    Defeated = 3,
    Succeeded = 4,
    Queued = 5,
    Expired = 6,
    Executed = 7,
  }
});
