const hre = require("hardhat");
const fs = require("fs");

const {updateDeployments, aaveV3Mappings, connextParams} = require("./utils");

const CHAIN_NAME='goerli';
const CONNEXT_RINKEBY_HANDLER = connextParams.rinkeby.handler;

const providers = {
  rinkeby: {
    aavev3: {
      pool: "0xE039BdF1d874d27338e09B55CB09879Dedca52D8",
      dataProvider: "0xBAB2E7afF5acea53a43aEeBa2BA6298D8056DcE5",
    },
  },
};

const main = async() => {
  console.log(CHAIN_NAME);
  const _xrefi = await hre.ethers.getContractFactory("XRefiHelper");
  const xrefi = await _xrefi.deploy(
    CONNEXT_RINKEBY_HANDLER
  );

  await xrefi.deployed();
  console.log("xrefi deployed to:", xrefi.address);

  const AaveV3 = await hre.ethers.getContractFactory("AaveV3");
  const aavev3 = await AaveV3.deploy(
    xrefi.address,
    providers.rinkeby.aavev3.pool,
    providers.rinkeby.aavev3.dataProvider
  );

  await aavev3.deployed();
  console.log("AaveV3 deployed to:", aavev3.address);

  let tx;
  for (const asset of Object.values(aaveV3Mappings)) {
    tx = await aavev3.addATokenMapping(asset.address, asset.aToken);
    await tx.wait();
    tx = await aavev3.addDebtTokenMapping(asset.address, asset.debtToken);
    await tx.wait();
  }
  console.log("AaveV3 asset mappings ready!");

  let newdeployData = {
    chain: CHAIN_NAME,
    connextDomainId: connextParams.rinkeby.domainId,
    xrefi: {address: xrefi.address},
    loanProvider: {address: aavev3.address}
  }

  await updateDeployments(CHAIN_NAME, newdeployData);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
