//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IElementManager} from "./interfaces/IElementManager.sol";

contract ElementManager is IElementManager {
    Element[] public override elements;
    uint256 public override elementsId;
    // id -> index
    mapping(uint256 => uint256) public override elementsIndexes;

    uint256 public override sizeLimit; // DON'T CHANGE
    uint256 private maxElementsCount;
    uint256 private elementsRange;

    // DON'T CHANGE
    constructor(
        uint256 _elementsToOpen,
        uint256 _sizeLimit,
        uint256 _elementsRange
    ) {
        require(
            _elementsToOpen > (_elementsRange / 2),
            "ElementManager::constructor: ELEMENTSRANGE_MORE_THAN_ELEMENTSTOOPEN"
        );
        for (uint256 i; i < _elementsToOpen; i++) {
            bool isClosable = ((uint256(
                keccak256(abi.encodePacked(block.difficulty, block.timestamp, elements.length))
            ) % 2) == 0);
            _openElement(isClosable);
        }

        sizeLimit = _sizeLimit;
        maxElementsCount = _elementsToOpen + (_elementsRange / 2);
        elementsRange = _elementsRange;
    }

    function getElement(uint256 _id) external view override returns (Element memory) {
        return elements[elementsIndexes[_id]];
    }

    function getAllElementsLength() external view override returns (uint256) {
        return elements.length;
    }

    function getAllElements() external view override returns (Element[] memory) {
        return elements;
    }

    function getElementsPage(uint256 _cursor, uint256 _count)
        public
        view
        override
        returns (Element[] memory elementsPage, uint256 newCursor)
    {
        if (_cursor >= elements.length) {
            return (elementsPage, 0);
        }

        if (_cursor + _count >= elements.length) {
            _count = elements.length - _cursor;
        } else {
            newCursor = _cursor + _count;
        }

        elementsPage = new Element[](_count);
        for (uint256 i; i < _count; i++) {
            elementsPage[i] = elements[_cursor + i];
        }
    }

    function getClosableElements(uint256 _cursor, uint256 _count)
        external
        view
        override
        returns (
            uint256 newCursor,
            bool closureNeeded,
            uint256[] memory ids
        )
    {
        uint256 count;

        Element[] memory elementsPage;
        (elementsPage, newCursor) = getElementsPage(_cursor, _count);

        uint256[] memory toClose = new uint256[](sizeLimit);

        for (uint256 i; i < elementsPage.length; i++) {
            if (elementsPage[i].isClosable) {
                toClose[count] = elementsPage[i].id;
                count++;

                if (count == sizeLimit) {
                    newCursor = _cursor + sizeLimit;
                    break;
                }
            }
        }

        uint256[] memory toCloseTrimmedArray = new uint256[](count);

        for (uint256 i; i < count; i++) {
            toCloseTrimmedArray[i] = toClose[i];
        }

        ids = toCloseTrimmedArray;

        if (count > 0) {
            closureNeeded = true;
        }
    }

    function closeElements(uint256[] memory ids) external override {
        require(ids.length <= sizeLimit, "ElementManager::closeElements: TOO_MANY_ELEMENTS");
        for (uint256 i; i < ids.length; i++) {
            _closeElement(ids[i]);
        }
        _shakeElements(); // DON'T CHANGE
    }

    // DON'T CHANGE
    function _shakeElements() internal {
        uint256 randomUint = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, elements.length)));
        uint256 delta = randomUint % elementsRange;
        uint256 newElementsCount = maxElementsCount - delta;
        bool needsOpen = newElementsCount > elements.length;

        uint256 count = (needsOpen ? (newElementsCount - elements.length) : (elements.length - newElementsCount));
        for (uint256 i; i < count; i++) {
            if (needsOpen) {
                bool isClosable = ((uint256(
                    keccak256(abi.encodePacked(block.difficulty + i, block.timestamp, elements.length))
                ) % 2) == 0);
                _openElement(isClosable);
            } else {
                uint256 elementIndex = uint256(
                    keccak256(abi.encodePacked(block.difficulty, block.timestamp + i, elements.length))
                ) % elements.length;
                _deleteElement(elements[elementIndex].id);
            }
        }

        for (uint256 i; i < delta; i++) {
            uint256 elementIndex = uint256(
                keccak256(abi.encodePacked(block.difficulty + i, block.timestamp, elements.length))
            ) % elements.length;
            elements[elementIndex].isClosable = !elements[elementIndex].isClosable;
        }
    }

    function _closeElement(uint256 _id) internal {
        Element storage element = elements[elementsIndexes[_id]];
        if (element.id == _id && element.isClosable) {
            _deleteElement(_id);
        }
    }

    function _openElement(bool _needsClosure) internal {
        Element memory element = Element({id: elementsId, isClosable: _needsClosure});
        elementsId++;
        elements.push(element);
        elementsIndexes[element.id] = elements.length - 1;
    }

    function _deleteElement(uint256 _id) internal {
        elements[elementsIndexes[_id]] = elements[elements.length - 1];
        elementsIndexes[elements[elements.length - 1].id] = elementsIndexes[_id];
        elements.pop();
        delete elementsIndexes[_id];
    }
}
