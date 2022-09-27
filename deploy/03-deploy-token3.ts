import { artifacts, ethers, network, upgrades } from "hardhat";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { developmentChains } from "../helper-hardhat.config";

const BASE_FEE = ethers.utils.parseEther("0.25");

// Calculated value based on the gas price on the chain
const GAS_PRICE_LINK = 1e9;

const deployToken3: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, log, save } = deployments;

  const { deployer } = await getNamedAccounts();
  const { chainId } = network.config;

  const Token3Factory = await ethers.getContractFactory("Token3");
  const token3 = await Token3Factory.deploy();
  await token3.deployed();

  console.log(token3.address, " Token3 address");

  const artifact = await deployments.getArtifact("Token3");

  await save("Token3", {
    address: token3.address,
    ...artifact,
  });
};

export default deployToken3;

deployToken3.tags = ["all", "token3"];
