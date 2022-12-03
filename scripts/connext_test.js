require("dotenv").config();
const hre = require("hardhat");
const fs = require("fs");

const { readDeployments, connextParams, testParams } = require("./utils");

const CHAIN_A_NAME = "goerli"; // initiation chain
const CHAIN_B_NAME = "mumbai"; // receiving chain

const CHAIN_A_COLLATERAL_ASSET = testParams.testAssets.goerli.collateral;
const CHAIN_B_COLLATERAL_ASSET = testParams.testAssets.mumbai.collateral;

const CHAIN_A_DEBT_ASSET = testParams.testAssets.goerli.debt;
const CHAIN_B_DEBT_ASSET = testParams.testAssets.mumbai.debt;

const main = async () => {
  const local = await readDeployments(CHAIN_A_NAME);
  const remote = await readDeployments(CHAIN_B_NAME);

  if (!process.env.TEST_USER_PKEY) {
    throw "Please set TEST_USER_PKEY in ./root/.env"
  }
  const testUser = new hre.ethers.Wallet(process.env.TEST_USER_PKEY, hre.ethers.provider);

  const xrefi = await hre.ethers.getContractAt("XRefiHelper", local.teleporter.address);

  // execute xcall with Connext
  console.log(`...begin 'initiateLoanTransfer()' xcall on ${CHAIN_A_NAME} teleporter`);
  let tx = await xrefi.connect(testUser).repayAndTransfer(
    connextParams.goerli.domainId, // originDomain
    connextParams.mumbai.domainId, // destinantionDomain
    local.loanProvider.address,
    remote.loanProvider.address,
    CHAIN_A_COLLATERAL_ASSET,
    CHAIN_B_COLLATERAL_ASSET,
    testParams.testAmounts.collateralAmount,
    CHAIN_A_DEBT_ASSET,
    CHAIN_B_DEBT_ASSET,
    testParams.testAmounts.debtAmount,
    {gasLimit: 8000000}
  );
  await tx.wait();
  console.log(`...xcall submitted!`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});