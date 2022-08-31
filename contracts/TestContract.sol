//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ITestContract} from "./interfaces/ITestContract.sol";

contract TestContract is ITestContract {
    
    Position[] public override positions;
    uint256 public override positionsId;
    mapping(uint256 => uint256) public override positionIndexes;
    uint256 public override closureOutputSize;

    uint256 private initialPositionsCount;
    uint256 private maxDeltaPositionsCount;

    constructor(uint256 _positionsToOpen, uint256 _closureOutputSize, uint256 _maxDeltaPositionsCount) {
        require(_positionsToOpen > _maxDeltaPositionsCount, "TestContract::constructor: MAXDELTAPOSITIONSCOUNT_MORE_THAN_POSITIONSTOOPEN");
        for (uint256 i; i < _positionsToOpen; i++) { 
            bool needsClosure = ((uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, positions))) % 2) == 0);
            _openPosition(needsClosure);
        }
        closureOutputSize = _closureOutputSize;

        initialPositionsCount = _positionsToOpen;
        maxDeltaPositionsCount = _maxDeltaPositionsCount;
    }

    function closePosition(uint256 _id) public override {
        Position storage position = positions[positionIndexes[_id]];
        require(position.id == _id, "TestContract::closePosition: POSITION_DOES_NOT_EXIST");
        require(position.needsClosure, "TestContract::closePosition: POSITION_DOES_NOT_NEED_TO_BE_CLOSED");
        _deletePosition(_id);
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
        external
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
            Position[] positionsToClose
        )
    {
        uint256 count;

        Position[] memory positions;
        (positions, newCursor) = getPositionsArray(_cursor, _count);

        for (uint256 i; i < positions.length; i++) {
            if (positions[i].needsClosure) {
                positionsToClose[count] = positions[i];
                count++;
            }

            if (count == closureOutputSize) {
                break;
            }
        }

        if (count > 0) {
            upkeepNeeded = true;
        }

        return (newCursor, upkeepNeeded, positionsToClose);
    }

    function performUpkeep(Position[] positionsToClose) external override {
        require(positionsToClose.length <= closureOutputSize, "TestContract::performUpkeep: TOO_MANY_POSITIONS");
        for (uint256 i; i < positionsToClose.length; i++) {
            closePosition(positionsToClose[i].id);
        }
        _shakePositions();
    }

    function _shakePositions() internal {
        uint256 isIncrease = ((uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, positions))) % 2) == 0);
        uint256 delta = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, positions))) % maxDeltaPositionsCount;
        uint256 newPositionsCount = isIncrease ? (initialPositionsCount + delta) : (initialPositionsCount - delta);

        bool needsOpen = newPositionsCount > positions.length;

        for (uint256 i; i < (needsOpen ? (newPositionsCount - positions.length) : (positions.length - newPositionsCount)); i++) {
            if (needsOpen) {
                bool needsClosure = ((uint(keccak256(abi.encodePacked(block.difficulty + i, block.timestamp, positions))) % 2) == 0);
                _openPosition(needsClosure);
            } else {
                uint256 positionId = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp + i, positions))) % positions.length;
                _deletePosition(positions[positionId].id);
            }
        }

        for (uint256 i; i < positions.length; i++) {
            bool needsClosure = ((uint(keccak256(abi.encodePacked(block.difficulty + i, block.timestamp, positions))) % 2) == 0);
            positions[positionId].needsClosure = needsClosure;
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

    function _updatePosition(uint256 _id, bool _needsClosure) internal {
        positions[_id].needsClosure = _needsClosure;
    }
}