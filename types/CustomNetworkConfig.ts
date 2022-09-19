import {
  HardhatUserConfig,
  NetworksUserConfig,
  ProjectPathsUserConfig,
  SolidityUserConfig,
} from "hardhat/types";

export interface CustomNetworkConfig extends HardhatUserConfig {
  defaultNetwork?: string;
  paths?: ProjectPathsUserConfig;
  networks?: NetworksUserConfig;
  solidity?: SolidityUserConfig;
  mocha?: Mocha.MochaOptions;
  verifyContract: boolean;
  nome: string;
  deploy_parameters: DeployParameters;
  blockConfirmations?: number;
}

interface DeployParameters {
  bidTimeTolerance: number;
  auctionDuration: number;
  initialBid: string;
  percIncrement: number;
  executorMinDelay: number;
  executorProposers: any[];
  executors: any[];
  quorumPercentage: number;
  votingPeriod: number;
  votingDelay: number;
  vetoUntil: number;
}
