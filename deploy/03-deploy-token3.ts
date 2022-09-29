import { artifacts, ethers, network, upgrades } from "hardhat";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { developmentChains } from "../helper-hardhat.config";

const BASE_FEE = ethers.utils.parseEther("0.25");

// Calculated value based on the gas price on the chain
const GAS_PRICE_LINK = 1e9;

const deployToken3: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, log, save, get } = deployments;

  const { deployer } = await getNamedAccounts();
  const { chainId } = network.config;
  const senate = await get("RepublicSenate");

  const Token3Factory = await ethers.getContractFactory("Token3");
  const token3 = await upgrades.deployProxy(Token3Factory, [senate.address]);
  await token3.deployed();

  console.log(token3.address, " Token3(proxy) address");
  console.log(
    await upgrades.erc1967.getImplementationAddress(token3.address),
    " getImplementationAddress"
  );
  console.log(
    await upgrades.erc1967.getAdminAddress(token3.address),
    " getAdminAddress"
  );

  const artifact = await deployments.getArtifact("Token3");

  await save("Token3", {
    address: token3.address,
    ...artifact,
  });
};

export default deployToken3;

deployToken3.tags = ["all", "token3"];
