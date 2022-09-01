import { ethers } from 'hardhat';
import { Overrides } from 'ethers';

const _overrides: Overrides = {
  gasLimit: 30000000,
};

async function main() {
  const positionsToOpen = "100";
  const closureOutputSize = "10";
  const positionsRange = "20";

  const TestContract = await ethers.getContractFactory('TestContract');
  const overrides: Overrides = { ..._overrides, gasPrice: 10000000000 };
  const testContract = await TestContract.deploy(positionsToOpen, closureOutputSize, positionsRange, overrides);

  await testContract.deployed();

  console.log('TestContract deployed to:', testContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
