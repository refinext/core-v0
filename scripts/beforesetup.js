const hre = require("hardhat");
const fs = require("fs");

const { readDeployments } = require("./utils");

const CHAIN_NAME='rinkeby';

// const CONNEXT_RINKEBY_TEST_TOKEN = "0x3FFc03F05D1869f493c7dbf913E636C6280e0ff9";

const main = async () => {
  console.log(CHAIN_NAME);
  const goerli = await readDeployments("goerli");

  // Get rinkeby xrefi
  const local = deployedRinkebyData;
  console.log(`...setting up the ${CHAIN_NAME} XRefinancer`);
  const xrefi = await hre.ethers.getContractAt("XRefinancer", local.xrefi.address);
  let tx = await xrefi.setLoanProvider(local.connextDomainId, local.loanProvider.address, true);
  await tx.wait();
  console.log(`...recorded ${local.chain} loan provider`);

  const ref = deployedKovanData;
  tx = await xrefi.setLoanProvider(ref.connextDomainId, ref.loanProvider.address, true);
  await tx.wait();
  console.log(`...recorded ${ref.chain} loan provider`);
  tx = await xrefi.setxrefi(ref.connextDomainId, ref.xrefi.address);
  await tx.wait();
  console.log(`...recorded ${ref.chain} xrefi`);

//   console.log(`...setting connext ${CHAIN_NAME} test token ${CONNEXT_RINKEBY_TEST_TOKEN}`);
//   tx = await xrefi.setTestToken(CONNEXT_RINKEBY_TEST_TOKEN);
//   tx.wait();
//   console.log(`...test token set complete!`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});