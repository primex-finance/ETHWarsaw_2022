import {ethers} from 'hardhat';
import {Overrides} from 'ethers';

const _overrides: Overrides = {
  gasLimit: 30000000,
};

async function main() {
  const elementsToOpen = '100';
  const sizeLimit = '10';
  const elementsRange = '20';

  const ElementManager = await ethers.getContractFactory('ElementManager');
  const overrides: Overrides = {..._overrides, gasPrice: 10000000000};
  const elementManager = await ElementManager.deploy(elementsToOpen, sizeLimit, elementsRange, overrides);

  await elementManager.deployed();

  console.log('ElementManager deployed to:', elementManager.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
