import {ethers, waffle, network} from 'hardhat';
import chai from 'chai';

import TestContractArtifact from '../artifacts/contracts/TestContract.sol/TestContract.json';
import {TestContract} from '../typechain/TestContract';
import {SignerWithAddress} from '@nomiclabs/hardhat-ethers/signers';

const {deployContract} = waffle;
const {expect} = chai;

import {BigNumber, Overrides} from 'ethers';

const _overrides: Overrides = {
  gasLimit: 30000000,
};

describe('TestContract', () => {
  let snapshotId: number;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;

  let testContract: TestContract;

  const positionsToOpen = 100;
  const closureOutputSize = 10;
  const positionsRange = 20;

  before(async () => {
    [owner, addr1] = await ethers.getSigners();
    testContract = (await deployContract(owner, TestContractArtifact, [
      positionsToOpen,
      closureOutputSize,
      positionsRange,
    ])) as TestContract;
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
    expect(await testContract.connect(addr1).positionsId()).to.be.equal(positionsToOpen);
    expect(await testContract.connect(addr1).closureOutputSize()).to.be.equal(closureOutputSize);
  });

  it('Should getPosition', async () => {
    expect(await testContract.connect(addr1).getPosition(0));
  });

  it('Should getAllPositionsLength', async () => {
    expect(await testContract.connect(addr1).getAllPositionsLength()).to.be.equal(positionsToOpen);
  });

  it('Should getAllPositions', async () => {
    expect((await testContract.connect(addr1).getAllPositions()).length).to.be.equal(positionsToOpen);
  });

  it('Should getPositionsArray', async () => {
    const cursor = 1;
    const count = 5;
    const tx = await testContract.connect(addr1).getPositionsArray(cursor, count);
    expect(tx.positionsArray.length).to.be.equal(count);
    expect(tx.newCursor).to.be.equal(cursor + count);
  });

  it('Should getPositionsArray if cursor >= positions length', async () => {
    const cursor = 200;
    const count = 5;
    const tx = await testContract.connect(addr1).getPositionsArray(cursor, count);
    expect(tx.positionsArray.length).to.be.equal(0);
    expect(tx.newCursor).to.be.equal(0);
  });

  it('Should getPositionsArray if cursor + count >= positions length', async () => {
    const positionsLength = (await testContract.connect(addr1).getAllPositionsLength()).toNumber();
    const cursor = positionsLength - 2;
    const count = 4;
    const tx = await testContract.connect(addr1).getPositionsArray(cursor, count);
    expect(tx.positionsArray.length).to.be.equal(positionsLength - cursor);
    expect(tx.newCursor).to.be.equal(0);
  });

  it('Should checkPositionUpkeep', async () => {
    const cursor = 1;
    const count = 5;
    const tx = await testContract.connect(addr1).checkPositionUpkeep(cursor, count);
    expect(tx.newCursor).to.be.equal(cursor + count);
    expect(tx.upkeepNeeded).to.be.equal(tx.positionsToCloseIds.length > 0);
  });

  it('Should checkPositionUpkeep more then max output size', async () => {
    const cursor = 0;
    const count = 100;
    const tx = await testContract.connect(addr1).checkPositionUpkeep(cursor, count);
    expect(tx.newCursor).to.be.equal(cursor + closureOutputSize);
    expect(tx.upkeepNeeded).to.be.equal(tx.positionsToCloseIds.length > 0);
  });

  it('Should performUpkeep', async () => {
    const cursor = 0;
    const count = 100;
    const checkTx = await testContract.connect(addr1).checkPositionUpkeep(cursor, count);
    expect(checkTx.newCursor).to.be.equal(cursor + closureOutputSize);
    expect(checkTx.upkeepNeeded).to.be.equal(checkTx.positionsToCloseIds.length > 0);

    const overrides: Overrides = {..._overrides, gasPrice: 10000000000};
    expect(await testContract.connect(addr1).performUpkeep(checkTx.positionsToCloseIds, overrides));
    for (let i = 0; i < checkTx.positionsToCloseIds.length; i++) {
      expect((await testContract.connect(addr1).getPosition(checkTx.positionsToCloseIds[i])).id).to.be.not.equal(
        checkTx.positionsToCloseIds[i],
      );
    }
    expect(await testContract.connect(addr1).getAllPositionsLength()).to.be.within(
      positionsToOpen - positionsRange / 2,
      positionsToOpen + positionsRange / 2,
    );
  });

  it('Should performUpkeep with with no need to close position', async () => {
    const positions = await testContract.connect(addr1).getAllPositions();
    let position: [BigNumber, boolean] & {id: BigNumber; needsClosure: boolean};
    for (let i = 0; i < positions.length; i++) {
      if (!positions[i].needsClosure) {
        position = positions[i];
        break;
      }
    }

    const overrides: Overrides = {..._overrides, gasPrice: 10000000000};
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    expect(await testContract.connect(addr1).performUpkeep([position!.id], overrides));
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    expect((await testContract.connect(addr1).getPosition(position!.id)).id).to.be.equal(position!.id);
    expect(await testContract.connect(addr1).getAllPositionsLength()).to.be.within(
      positionsToOpen - positionsRange / 2,
      positionsToOpen + positionsRange / 2,
    );
  });
});
