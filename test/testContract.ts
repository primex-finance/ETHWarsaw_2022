import {ethers, waffle, network} from 'hardhat';
import chai from 'chai';

import TestContractArtifact from '../artifacts/contracts/ElementManager.sol/ElementManager.json';
import {ElementManager} from '../typechain/ElementManager';
import {SignerWithAddress} from '@nomiclabs/hardhat-ethers/signers';

const {deployContract} = waffle;
const {expect} = chai;

import {BigNumber, Overrides} from 'ethers';

const _overrides: Overrides = {
  gasLimit: 30000000,
};

describe('ElementManager', () => {
  let snapshotId: number;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;

  let testContract: ElementManager;

  const elementsToOpen = 100;
  const sizeLimit = 10;
  const elementsRange = 20;

  before(async () => {
    [owner, addr1] = await ethers.getSigners();
    testContract = (await deployContract(owner, TestContractArtifact, [
      elementsToOpen,
      sizeLimit,
      elementsRange,
    ])) as ElementManager;
  });

  beforeEach(async function () {
    snapshotId = (await network.provider.request({
      method: 'evm_snapshot',
      params: [],
    })) as number;
  });
  afterEach(async function () {
    await network.provider.request({
      method: 'evm_revert',
      params: [snapshotId],
    });
  });

  it('Should check initials', async () => {
    expect(await testContract.connect(addr1).elementsId()).to.be.equal(elementsToOpen);
    expect(await testContract.connect(addr1).sizeLimit()).to.be.equal(sizeLimit);
  });

  it('Should getElement', async () => {
    expect(await testContract.connect(addr1).getElement(0));
  });

  it('Should getAllElementsLength', async () => {
    expect(await testContract.connect(addr1).getAllElementsLength()).to.be.equal(elementsToOpen);
  });

  it('Should getAllElements', async () => {
    expect((await testContract.connect(addr1).getAllElements()).length).to.be.equal(elementsToOpen);
  });

  it('Should getElementsPage', async () => {
    const cursor = 1;
    const count = 5;
    const tx = await testContract.connect(addr1).getElementsPage(cursor, count);
    expect(tx.elementsPage.length).to.be.equal(count);
    expect(tx.newCursor).to.be.equal(cursor + count);
  });

  it('Should getElementsPage if cursor >= elements length', async () => {
    const cursor = 200;
    const count = 5;
    const tx = await testContract.connect(addr1).getElementsPage(cursor, count);
    expect(tx.elementsPage.length).to.be.equal(0);
    expect(tx.newCursor).to.be.equal(0);
  });

  it('Should getElementsPage if cursor + count >= elements length', async () => {
    const elementsLength = (await testContract.connect(addr1).getAllElementsLength()).toNumber();
    const cursor = elementsLength - 2;
    const count = 4;
    const tx = await testContract.connect(addr1).getElementsPage(cursor, count);
    expect(tx.elementsPage.length).to.be.equal(elementsLength - cursor);
    expect(tx.newCursor).to.be.equal(0);
  });

  it('Should getClosableElements', async () => {
    const cursor = 1;
    const count = 5;
    const tx = await testContract.connect(addr1).getClosableElements(cursor, count);
    expect(tx.newCursor).to.be.equal(cursor + count);
    expect(tx.closureNeeded).to.be.equal(tx.ids.length > 0);
  });

  it('Should getClosableElements more then max output size', async () => {
    const cursor = 0;
    const count = 100;
    const tx = await testContract.connect(addr1).getClosableElements(cursor, count);
    expect(tx.newCursor).to.be.equal(cursor + sizeLimit);
    expect(tx.closureNeeded).to.be.equal(tx.ids.length > 0);
  });

  it('Should closeElements', async () => {
    const cursor = 0;
    const count = 100;
    const checkTx = await testContract.connect(addr1).getClosableElements(cursor, count);
    expect(checkTx.newCursor).to.be.equal(cursor + sizeLimit);
    expect(checkTx.closureNeeded).to.be.equal(checkTx.ids.length > 0);

    const overrides: Overrides = {..._overrides, gasPrice: 10000000000};
    expect(await testContract.connect(addr1).closeElements(checkTx.ids, overrides));
    for (let i = 0; i < checkTx.ids.length; i++) {
      expect((await testContract.connect(addr1).getElement(checkTx.ids[i])).id).to.be.not.equal(checkTx.ids[i]);
    }
    expect(await testContract.connect(addr1).getAllElementsLength()).to.be.within(
      elementsToOpen - elementsRange / 2,
      elementsToOpen + elementsRange / 2,
    );
  });

  it('Should closeElements with with no need to close element', async () => {
    const elements = await testContract.connect(addr1).getAllElements();
    let element: [BigNumber, boolean] & {id: BigNumber; isClosable: boolean};
    for (let i = 0; i < elements.length; i++) {
      if (!elements[i].isClosable) {
        element = elements[i];
        break;
      }
    }

    const overrides: Overrides = {..._overrides, gasPrice: 10000000000};
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    expect(await testContract.connect(addr1).closeElements([element!.id], overrides));
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    expect((await testContract.connect(addr1).getElement(element!.id)).id).to.be.equal(element!.id);
    expect(await testContract.connect(addr1).getAllElementsLength()).to.be.within(
      elementsToOpen - elementsRange / 2,
      elementsToOpen + elementsRange / 2,
    );
  });
});
