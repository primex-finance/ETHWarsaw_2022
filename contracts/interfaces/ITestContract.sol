//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ITestContract {
    struct Position {
        uint256 id;
        bool needsClosure;
    }

    function positions(uint256 _index) external view returns (uint256 id, bool needsClosure);

    function positionsId() external view returns (uint256);

    function positionIndexes(uint256) external view returns (uint256);

    function closureOutputSize() external view returns (uint256);

    function getPosition(uint256 _id) external view returns (Position memory);

    function getAllPositionsLength() external view returns (uint256);

    function getAllPositions() external view returns (Position[] memory);

    function getPositionsArray(uint256 cursor, uint256 count)
        external
        view
        returns (Position[] memory positionsArray, uint256 newCursor);

    function checkPositionUpkeep(uint256 _cursor, uint256 _count)
        external
        returns (
            uint256 newCursor,
            bool upkeepNeeded,
            uint256[] memory positionsToCloseIds
        );

    function performUpkeep(uint256[] memory positionsToCloseIds) external;
}
