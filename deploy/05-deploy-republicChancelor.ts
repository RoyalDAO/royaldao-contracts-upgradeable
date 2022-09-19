import { artifacts, ethers, network, upgrades } from "hardhat";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { developmentChains } from "../helper-hardhat.config";
import { burnAddress, getAddress } from "../scripts/utils";
import { RepublicExecutor } from "../typechain-types";

const BASE_FEE = ethers.utils.parseEther("0.25");

// Calculated value based on the gas price on the chain
const GAS_PRICE_LINK = 1e9;

const deployChancelor: DeployFunction = async (
  hre: HardhatRuntimeEnvironment
) => {
  const { deployments, getNamedAccounts } = hre;
  const { get, save } = deployments;

  const executorMinDelay = 272;
  const quorum = 25; //percentage
  const votingPeriod = 500; //~110 minutes in blocks
  const votingDelay = 30; //~7 minutes in blocks
  const tokenTreshold = 1; //~7 minutes in blocks

  const { deployer } = await getNamedAccounts();
  const { chainId } = network.config;

  const token1 = await get("Token1");
  const token2 = await get("Token2");

  const executorFactory = await ethers.getContractFactory("RepublicExecutor");

  const executor = await get("RepublicExecutor");
  const executorInstance: RepublicExecutor = executorFactory.attach(
    executor.address
  );

  console.log(`Token1 address: ${token1.address}`);
  console.log(`Executor address: ${executor.address}`);
  const chancelorFactory = await ethers.getContractFactory("RepublicChancelor");
  const chancelor = await upgrades.deployProxy(chancelorFactory, [
    [token1.address, token2.address],
    [],
    executor.address,
    votingDelay,
    votingPeriod,
    tokenTreshold,
    quorum,
  ]);

  await chancelor.deployed();

  console.log(chancelor.address, " Chancelor(proxy) address");
  console.log(
    await upgrades.erc1967.getImplementationAddress(chancelor.address),
    " getImplementationAddress"
  );
  console.log(
    await upgrades.erc1967.getAdminAddress(chancelor.address),
    " getAdminAddress"
  );

  const owner = getAddress("owner");

  const proposer_role = await executorInstance.PROPOSER_ROLE();
  const executor_role = await executorInstance.EXECUTOR_ROLE();
  const timelock_admin_role = await executorInstance.TIMELOCK_ADMIN_ROLE();
  const canceler_role = await executorInstance.CANCELLER_ROLE();
  await executorInstance.grantRole(proposer_role, chancelor.address);
  await executorInstance.grantRole(canceler_role, chancelor.address);
  await executorInstance.grantRole(executor_role, burnAddress);
  const tx = await executorInstance.revokeRole(timelock_admin_role, owner);
  await tx.wait(1);

  console.log("Guess what? Now you can't do anything!");

  const artifact = await deployments.getArtifact("RepublicChancelor");

  await save("RepublicChancelor", {
    address: chancelor.address,
    ...artifact,
  });
};

export default deployChancelor;

deployChancelor.tags = ["all", "chancelor"];
