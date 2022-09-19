import { BigNumberish, ethers } from "ethers";

export interface networkConfigItem {
  blockConfirmations?: number;
  VRFCoordinatorV2: string;
  // entranceFee: BigNumberish;
  gasLane: string;
  callBackGasLimit: string;
  interval: string;
  subscriptionId?: string;
  deploy_parameters?: DeployParameters;
}

interface DeployParameters {
  executorMinDelay: number;
  executorProposers: any[];
  executors: any[];
  quorumPercentage: number;
  votingPeriod: number;
  votingDelay: number;
  vetoUntil: number;
}

export interface networkConfigInfo {
  [key: number]: networkConfigItem;
}

const networkConfig: networkConfigInfo = {
  5: {
    blockConfirmations: 6,
    // entranceFee: ethers.utils.parseEther("0.01"),
    VRFCoordinatorV2: "0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D",
    gasLane:
      "0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15",
    callBackGasLimit: "500000",
    interval: "120",
    subscriptionId: "505",
    deploy_parameters: {
      executorMinDelay: 272, //1 hour
      executorProposers: [],
      executors: [],
      quorumPercentage: 25, //25%
      votingPeriod: 272, //1 hour
      votingDelay: 272, //1 hour
      vetoUntil: 50,
    },
  },
  1337: {
    blockConfirmations: 1,
    // entranceFee: ethers.utils.parseEther("0.01"),
    VRFCoordinatorV2: "0x0000",
    gasLane:
      "0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc",
    callBackGasLimit: "500000",
    interval: "30",
  },
};

const developmentChains = ["hardhat", "localhost"];

export { networkConfig, developmentChains };
