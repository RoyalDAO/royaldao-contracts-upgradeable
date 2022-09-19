import { artifacts, ethers, network, upgrades } from "hardhat";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { developmentChains } from "../helper-hardhat.config";

const BASE_FEE = ethers.utils.parseEther("0.25");

// Calculated value based on the gas price on the chain
const GAS_PRICE_LINK = 1e9;

const deployExecutor: DeployFunction = async (
  hre: HardhatRuntimeEnvironment
) => {
  const { deployments, getNamedAccounts } = hre;
  const { get, save } = deployments;

  const { deployer } = await getNamedAccounts();
  const { chainId } = network.config;

  const executorFactory = await ethers.getContractFactory("RepublicExecutor");
  const executorMinDelay = 272; //1 hour
  const executorProposers: any[] = [];
  const executors: any[] = [];

  const executor = await upgrades.deployProxy(executorFactory, [
    executorMinDelay,
    executorProposers,
    executors,
  ]);

  await executor.deployed();

  const executorInstance = await executorFactory.attach(executor.address);
  console.log(executor.address, " Executor(proxy) address");
  console.log(
    await upgrades.erc1967.getImplementationAddress(executor.address),
    " getImplementationAddress"
  );
  console.log(
    await upgrades.erc1967.getAdminAddress(executor.address),
    " getAdminAddress"
  );

  console.log(`Executor min delay: ${await executorInstance.getMinDelay()}`);

  const artifact = await deployments.getArtifact("RepublicExecutor");

  await save("RepublicExecutor", {
    address: executor.address,
    ...artifact,
  });
};

export default deployExecutor;

deployExecutor.tags = ["all", "executor"];
