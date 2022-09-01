//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ITestContract} from "./interfaces/ITestContract.sol";

contract TestContract is ITestContract {
    
    Position[] public override positions;
    uint256 public override positionsId;
    mapping(uint256 => uint256) public override positionIndexes;
    uint256 public override closureOutputSize;

    uint256 private maxPositionsCount;
    uint256 private positionsRange;

    constructor(uint256 _positionsToOpen, uint256 _closureOutputSize, uint256 _positionsRange) {
        require(_positionsToOpen > (_positionsRange / 2), "TestContract::constructor: MAXDELTAPOSITIONSCOUNT_MORE_THAN_POSITIONSTOOPEN");
        for (uint256 i; i < _positionsToOpen; i++) { 
            bool needsClosure = ((uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, positions.length))) % 2) == 0);
            _openPosition(needsClosure);
        }
        closureOutputSize = _closureOutputSize;

        maxPositionsCount = _positionsToOpen + (_positionsRange / 2);
        positionsRange = _positionsRange;
    }

    function getPosition(uint256 _id) external view override returns (Position memory) {
        return positions[positionIndexes[_id]];
    }

    function getAllPositionsLength() external view override returns (uint256) {
        return positions.length;
    }

    function getAllPositions() external view override returns (Position[] memory) {
        return positions;
    }

    function getPositionsArray(uint256 _cursor, uint256 _count)
        public
        view
        override
        returns (Position[] memory positionsArray, uint256 newCursor)
    {
        if (_cursor >= positions.length) {
            return (positionsArray, 0);
        }

        if (_cursor + _count >= positions.length) {
            _count = positions.length - _cursor;
        } else {
            newCursor = _cursor + _count;
        }

        positionsArray = new Position[](_count);
        for (uint256 i; i < _count; i++) {
            positionsArray[i] = positions[_cursor + i];
        }
    }

    function checkPositionUpkeep(        
        uint256 _cursor,
        uint256 _count
    )
        external
        view
        override
        returns(
            uint256 newCursor,
            bool upkeepNeeded,
            uint256[] memory positionsToCloseIds
        )
    {
        uint256 count;

        Position[] memory positionsArray;
        (positionsArray, newCursor) = getPositionsArray(_cursor, _count);

        uint256[] memory toClose = new uint256[](closureOutputSize);

        for (uint256 i; i < positionsArray.length; i++) {
            if (positionsArray[i].needsClosure) {
                toClose[count] = positionsArray[i].id;
                count++;

                if (count == closureOutputSize) {
                    newCursor = _cursor + closureOutputSize;
                    break;
                }
            }
        }

        uint256[] memory toCloseTrimmedArray = new uint256[](count);

        for (uint256 i; i < count; i++) {
            toCloseTrimmedArray[i] = toClose[i];
        }

        positionsToCloseIds = toCloseTrimmedArray;

        if (count > 0) {
            upkeepNeeded = true;
        }
    }

    function performUpkeep(uint256[] memory positionsToCloseIds) external override {
        require(positionsToCloseIds.length <= closureOutputSize, "TestContract::performUpkeep: TOO_MANY_POSITIONS");
        for (uint256 i; i < positionsToCloseIds.length; i++) {
            _closePosition(positionsToCloseIds[i]);
        }
        _shakePositions();
    }

    function _shakePositions() internal {
        uint256 randomUint = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, positions.length)));
        uint256 delta = randomUint % positionsRange;
        uint256 newPositionsCount = maxPositionsCount - delta;
        bool needsOpen = newPositionsCount > positions.length;

        uint256 count = (needsOpen ? (newPositionsCount - positions.length) : (positions.length - newPositionsCount));
        for (uint256 i; i < count; i++) {
            if (needsOpen) {
                bool needsClosure = ((uint(keccak256(abi.encodePacked(block.difficulty + i, block.timestamp, positions.length))) % 2) == 0);
                _openPosition(needsClosure);
            } else {
                uint256 positionIndex = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp + i, positions.length))) % positions.length;
                _deletePosition(positions[positionIndex].id);
            }
        }

        for (uint256 i; i < delta; i++) {
            uint256 positionIndex = uint(keccak256(abi.encodePacked(block.difficulty + i, block.timestamp, positions.length))) % positions.length;
            positions[positionIndex].needsClosure = !positions[positionIndex].needsClosure;
        }
    }

    function _closePosition(uint256 _id) internal {
        Position storage position = positions[positionIndexes[_id]];
        if (position.id == _id && position.needsClosure) {
            _deletePosition(_id);
        }
    }

    function _openPosition(bool _needsClosure) internal {
        Position memory position = Position({
            id: positionsId,
            needsClosure: _needsClosure
        });
        positionsId++;
        positions.push(position);
        positionIndexes[position.id] = positions.length - 1;
    }

    function _deletePosition(uint256 _id) internal {
        positions[positionIndexes[_id]] = positions[positions.length - 1];
        positionIndexes[positions[positions.length - 1].id] = positionIndexes[_id];
        positions.pop();
        delete positionIndexes[_id];
    }
}