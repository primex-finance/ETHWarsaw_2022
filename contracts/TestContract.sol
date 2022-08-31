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
            bool needsClosure = ((uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, positions))) % 2) == 0);
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
            uint256[] positionsToCloseIds
        )
    {
        uint256 count;

        Position[] memory positions;
        (positions, newCursor) = getPositionsArray(_cursor, _count);

        for (uint256 i; i < positions.length; i++) {
            if (positions[i].needsClosure) {
                positionsToCloseIds[count] = positions[i].id;
                count++;
            }

            if (count == closureOutputSize) {
                break;
            }
        }

        if (count > 0) {
            upkeepNeeded = true;
        }
    }

    function performUpkeep(uint256[] positionsToCloseIds) external override {
        require(positionsToCloseIds.length <= closureOutputSize, "TestContract::performUpkeep: TOO_MANY_POSITIONS");
        for (uint256 i; i < positionsToCloseIds.length; i++) {
            try _closePosition(positionsToCloseIds) {continue;} catch {continue;}
        }
        _shakePositions();
    }

    function _shakePositions() internal {
        uint256 randomUint = int(keccak256(abi.encodePacked(block.difficulty, block.timestamp, positions)));
        uint256 delta = randomUint % positionsRange;
        uint256 newPositionsCount = maxPositionsCount - delta;
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

        uint256 changedPositionsCount = randomUint % positionsRange;

        for (uint256 i; i < changedPositionsCount; i++) {
            uint256 positionId = uint(keccak256(abi.encodePacked(block.difficulty + i, block.timestamp, positions))) % positions.length;
            positions[positionId].needsClosure = needsClosure;
        }
    }

    function _closePosition(uint256 _id) internal {
        Position storage position = positions[positionIndexes[_id]];
        require(position.id == _id, "TestContract::closePosition: POSITION_DOES_NOT_EXIST");
        require(position.needsClosure, "TestContract::closePosition: POSITION_DOES_NOT_NEED_TO_BE_CLOSED");
        _deletePosition(_id);
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