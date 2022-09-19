import { BigNumber } from "ethers";

export const burnAddress = "0x0000000000000000000000000000000000000000";

let NON_FORKED_LOCAL_BLOCKCHAIN_ENVIRONMENTS: Array<string> = [
  "hardhat",
  "development",
  "ganache",
];
const LOCAL_BLOCKCHAIN_ENVIRONMENTS = () => {
  NON_FORKED_LOCAL_BLOCKCHAIN_ENVIRONMENTS.push(
    "mainnet-fork",
    "binance-fork",
    "matic-fork"
  );
  return NON_FORKED_LOCAL_BLOCKCHAIN_ENVIRONMENTS;
};

export async function verifyContract(contractAddress: string, args: any[]) {
  const { run } = require("hardhat");
  console.log("Verifying contract...");
  console.log(`Contract Address: ${contractAddress}`);
  console.log(`Arguments: ${args}`);

  console.log(`Etherscan API key: ${process.env.ETHERSCAN_API_KEY}`);
  try {
    const result = await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
    });
    console.log("Verifyied!");
    return true;
  } catch (err: any) {
    if (err.message.toLowerCase().includes("already verified"))
      console.log("Already Verified!");
    else console.error(err);
    return false;
  }
}

export async function verifyContractFile(
  contractAddress: string,
  contractFile: string,
  args: any[]
) {
  const { run } = require("hardhat");
  console.log("Verifying contract...");
  console.log(`Contract Address: ${contractAddress}`);
  console.log(`Arguments: ${args}`);

  console.log(`Etherscan API key: ${process.env.ETHERSCAN_API_KEY}`);
  try {
    const result = await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
      contract: contractFile,
    });
    console.log("Verifyied!");
    return true;
  } catch (err: any) {
    if (err.message.toLowerCase().includes("already verified"))
      console.log("Already Verified!");
    else console.error(err);
    return false;
  }
}

export async function getAccount(accountType: string, qtty: number = 0) {
  const { ethers, network } = require("hardhat");
  const accounts: any[] = await ethers.getSigners();

  if (
    accountType.toLowerCase() == "owner" ||
    accountType.toLowerCase() == "vetoer" ||
    accountType.toLowerCase() == "museum"
  )
    return accounts[0];
  else if (accountType.toLowerCase() == "artist") return accounts[1];
  else if (accountType.toLowerCase() == "malicious") return accounts[2];
  else if (accountType.toLowerCase() == "minters") {
    let minters: any[] = [];
    if (network.config.chainId != 1337) {
      console.log("No minters key on live network");
      return minters;
    }

    if (qtty >= 1) {
      for (let idx = 0; idx < qtty; idx++) {
        minters.push(accounts[idx + 3]);
      }
    } else minters.push(accounts[3]);
    return minters;
  }
}

export async function getAddress(accountType: string, qtty: number = 0) {
  const { ethers, network } = require("hardhat");
  const accounts = await ethers.getSigners();

  if (accountType.toLowerCase() == "owner") return accounts[0].address;
  else if (
    accountType.toLowerCase() == "vetoer" ||
    accountType.toLowerCase() == "museum"
  ) {
    if (network.config.nome?.toLowerCase() == "development")
      return accounts[0].address;
    else if (network.config.nome?.toLowerCase() == "rinkeby")
      return process.env.SAFE_WALLET;
    else if (network.config.nome?.toLowerCase() == "mainnet")
      return process.env.SAFE_WALLET_MAINNET;
    else return process.env.SAFE_WALLET;
  } else if (accountType.toLowerCase() == "artist") return accounts[1].address;
  else if (accountType.toLowerCase() == "malicious") return accounts[2].address;
  else if (accountType.toLowerCase() == "developer") return accounts[3].address;
  else if (accountType.toLowerCase() == "founders") {
    let founders = [];
    if (network.config.nome?.toLowerCase() != "development") {
      founders.push(process.env.FOUNDER_1);
      founders.push(process.env.FOUNDER_2);
      founders.push(process.env.FOUNDER_3);
      founders.push(process.env.FOUNDER_4);
    } else {
      for (let idx = 0; idx < 4; idx++) {
        founders.push(accounts[idx + 4].address);
      }
    }

    return founders;
  } else if (accountType.toLowerCase() == "minters") {
    let minters: any[] = [];

    if (network.config.nome?.toLowerCase() != "development") {
      console.log("No minters key on live network");
      return [];
    }

    if (qtty >= 1) {
      for (let idx = 0; idx < qtty; idx++) {
        minters.push(accounts[idx + 8].address);
      }
    } else minters.push(accounts[8].address);
    return minters;
  }
}

export function getProxyRegistry() {
  const { network } = require("hardhat");
  if (network.config.nome?.toLowerCase() == "rinkeby") {
    return "0xF57B2C51DED3A29E6891ABA85459D600256CF317";
  } else if (network.config.nome?.toLowerCase() == "mainnet") {
    return "0xA5409EC958C83C3F309868BABACA7C86DCB077C1";
  } else return burnAddress;
}

export function getWETHAddress() {
  const { network } = require("hardhat");
  if (network.config.nome?.toLowerCase() == "rinkeby")
    return "0xC778417E063141139FCE010982780140AA0CD5AB";
  else if (network.config.nome?.toLowerCase() == "mainnet")
    return "0xC02AAA39B223FE8D0A0E5C4F27EAD9083C756CC2";
  else if (network.config.nome?.toLowerCase() == "kovan")
    return "0xd0A1E359811322d97991E03f863a0C30C2cF029C";
  else if (network.config.nome?.toLowerCase() == "goerli")
    return "0x0Bb7509324cE409F7bbC4b701f932eAca9736AB7";
  //else if (network.config.nome?.toLowerCase() == "ropsten") return "0x0a180A76e4466bF68A7F86fB029BEd3cCcFaAac5"
  else return burnAddress;
}

export function isLocalNetwork(networkName?: string) {
  if (!networkName) {
    const { network } = require("hardhat");
    networkName = network.config.nome;
  }

  return networkName
    ? LOCAL_BLOCKCHAIN_ENVIRONMENTS().includes(networkName)
    : false;
}

export function encode_function_data(initializer?: any, args?: any[]) {
  const { web3 } = require("hardhat");
  if ((args?.length ?? 0) == 0 || !initializer)
    return web3.utils.hexToBytes("0x");

  return initializer.encode_input(args);
}

export function getHouseSeatName(houseSeat: BigNumber) {
  if (houseSeat.eq(1)) {
    return "HOUSE OF LORDS";
  } else if (houseSeat.eq(2)) {
    return "HOUSE OF COMMONS";
  } else if (houseSeat.eq(3)) {
    return "HOUSE OF BANNED";
  } else {
    return "NONE";
  }
}

export async function chainSleep(snoozzeTime: number) {
  const { network, ethers } = require("hardhat");
  const blockNumBefore = await ethers.provider.getBlockNumber();
  const blockBefore = await ethers.provider.getBlock(blockNumBefore);
  await network.provider.send("evm_mine", [
    blockBefore.timestamp + snoozzeTime,
  ]);
}

export async function chainMine(blocks: number) {
  const helpers = require("@nomicfoundation/hardhat-network-helpers");
  helpers.mine(blocks);
  //const { network } = require("hardhat")
  //await network.provider.send("hardhat_mine", [blocks])
}
