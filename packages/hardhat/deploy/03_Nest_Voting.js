// deploy/00_deploy_example_external_contract.js

const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy("NestVotingToken", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    log: true,
  });

  const NestVotingToken = await ethers.getContract("NestVotingToken");
};

module.exports.tags = ["NestVotingToken"];
