import { artifacts, ethers, network, upgrades } from "hardhat";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { developmentChains } from "../helper-hardhat.config";

const BASE_FEE = ethers.utils.parseEther("0.25");

// Calculated value based on the gas price on the chain
const GAS_PRICE_LINK = 1e9;

const deployToken2: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, log, save, get } = deployments;

  const { deployer } = await getNamedAccounts();
  const { chainId } = network.config;

  const senate = await get("RepublicSenate");

  const Token2Factory = await ethers.getContractFactory("Token2");
  const token2 = await upgrades.deployProxy(Token2Factory, [senate.address]);
  await token2.deployed();

  console.log(token2.address, " Token2(proxy) address");
  console.log(
    await upgrades.erc1967.getImplementationAddress(token2.address),
    " getImplementationAddress"
  );
  console.log(
    await upgrades.erc1967.getAdminAddress(token2.address),
    " getAdminAddress"
  );

  const artifact = await deployments.getArtifact("Token2");

  await save("Token2", {
    address: token2.address,
    ...artifact,
  });
};

export default deployToken2;

deployToken2.tags = ["all", "token2"];
