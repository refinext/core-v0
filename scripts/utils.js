const hre = require("hardhat");
const fs = require("fs");

const deploymentsPath = `${hre.config.paths.root}/scripts/deployed.json`;

const aaveV3Mappings = {
  // Rinkeby
  WETH: {
    address: "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6",
    aToken: "0x27B4692C93959048833f40702b22FE3578E77759",
    debtToken: "0xCAF956bD3B3113Db89C0584Ef3B562153faB87D5",
  },
  USDC: {
    address: "0xd35CCeEAD182dcee0F148EbaC9447DA2c4D449c4",
    aToken: "0x1Ee669290939f8a8864497Af3BC83728715265FF",
    debtToken: "0xF04958AeA8b7F24Db19772f84d7c2aC801D9Cf8b",
  }
};

const connextParams = {
  
  goerli: {
    testToken: "0x3FFc03F05D1869f493c7dbf913E636C6280e0ff9",
    handler: "0xEC3A723DE47a644b901DC269829bf8718F175EBF",
    chainId: 5,
    domainId: 3331
  }
}

const testParams = {
  testAssets: {
    goerli : {
      collateral: aaveV3Mappings.WETH.address,
      collateralReceiptToken: aaveV3Mappings.WETH.aToken,
      debt: aaveV3Mappings.USDC.address
    }
  },
  testAmounts: {
    collateralAmount: hre.ethers.utils.parseUnits("100", 100000000000000000), // assuming WBTC
    liquidityAmount: hre.ethers.utils.parseUnits("10000", 6), // assuming USDC
    debtAmount: hre.ethers.utils.parseUnits("250", 6), // assuming USDC
  }
}

const updateDeployments = async (chain, newDeployData) => {
  let deployData = [];
  if (fs.existsSync(deploymentsPath)) {
    deployData = JSON.parse(fs.readFileSync(deploymentsPath).toString());
    let chainData = deployData.find(e => e.chain == chain);
    const index = deployData.findIndex(e => e == chainData);
    if (index == -1) {
      deployData.push(newDeployData);
    } else {
      deployData[index] = newDeployData;
    }
  } else {
    deployData.push(newDeployData);
  }
  fs.writeFileSync(deploymentsPath, JSON.stringify(deployData, null, 2));
};

const readDeployments = async (chain) => {
  let deployData;
  if (fs.existsSync(deploymentsPath)) {
    deployData = JSON.parse(fs.readFileSync(deploymentsPath).toString());
    let chainData = deployData.find(e => e.chain == chain);
    if (chainData.chain == chain) {
      return chainData;
    } else {
      throw `No deployed data for chain ${chain} found!`;
    }
  } else {
    throw 'no /scripts/deployed.json file found!';
  }
}

module.exports = {
  updateDeployments,
  readDeployments,
  aaveV3Mappings,
  aaveV2Mappings,
  compoundMappings,
  connextParams,
  testParams
}