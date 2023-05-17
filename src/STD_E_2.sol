// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "forge-std/Test.sol";

contract STD_E_2 {

    uint256 constant private slotMask  = ((1<<8) - 1) << 248;
    uint256 constant private timeMask  = ((1<<32) - 1) << 224;
    uint256 constant private nonceMask = ((1<<11) - 1) << 213;
    uint256 constant private countMask = ((1<<4) - 1) << 209;

    struct Slot {
        uint32 time;
        uint8 nonce;
        uint8 count;
        uint24 p1;
        uint24 p2;
        uint24 p3;
        uint24 p4;
        uint24 p5;
        uint24 p6;
        uint24 p7;
        uint24 p8;
        uint24 p9;
        uint24 p10;
        uint24 p11;
    }

    // storage
    // 30|8|(19+17)*6|
    mapping(uint256 => uint256) public refs;

    function setAllSymbols(uint256 numberOfAllSymbols) public {
        uint256 numberOfAllSlots = (numberOfAllSymbols / 11) + 1;
        for (uint256 i = 0; i < numberOfAllSlots - 1; i++) {
            refs[i] = 11 << 209;
        }
        refs[numberOfAllSlots - 1] = (numberOfAllSymbols - ((numberOfAllSlots - 1)*11)) << 209;
    }

    function decodeSlot(uint256 slotID) public view returns(Slot memory s) {
        uint256 x = refs[slotID];
        s.time = uint32((x & timeMask) >> 224);
        s.nonce = uint8((x & nonceMask) >> 213);
        s.count = uint8((x & countMask) >> 209);
        s.p1 = uint24((x & (2**19 - 1) << 190) >> 190);
        s.p2 = uint24((x & (2**19 - 1) << 171) >> 171);
        s.p3 = uint24((x & (2**19 - 1) << 152) >> 152);
        s.p4 = uint24((x & (2**19 - 1) << 133) >> 133);
        s.p5 = uint24((x & (2**19 - 1) << 114) >> 114);
        s.p6 = uint24((x & (2**19 - 1) << 95) >> 95);
        s.p7 = uint24((x & (2**19 - 1) << 76) >> 76);
        s.p8 = uint24((x & (2**19 - 1) << 57) >> 57);
        s.p9 = uint24((x & (2**19 - 1) << 38) >> 38);
        s.p10 = uint24((x & (2**19 - 1) << 19) >> 19);
        s.p11 = uint24(x & (2**19 - 1));
    }

    // calldata
    // (8|32|11|19{1,11})*
    function relay0JqUC4ht0CQz() public {
        uint256 ptr = 4;
        uint256 word;
        uint256 time;
        uint256 slot;
        uint256 nonce;
        uint256 len;
        assembly {
            len := calldatasize()
            word := calldataload(ptr)
            slot := and(word, slotMask)
            ptr := add(ptr, 1)

            word := calldataload(ptr)
            time := and(word, timeMask)
            nonce := and(word, nonceMask)
        }
        uint256 bitIndex = 83; // 32 + 8 + 32 + 11

        while (ptr < len) {
            unchecked {
                uint256 slotVal = refs[slot >> 248];

                // TODO require(time > slotVal & (((1<<32) - 1) << 224), "invalid time");
                require(time > 0, "invalid time");
                // TODO require(nonce == ((slotVal & nonceMask) + (1<<213)) & nonceMask, "invalid nonce");
                require(nonce > 0, "invalid nonce");

                uint256 pricesBitsSize = ((slotVal & countMask) >> 209) * 19;

                slotVal |= (time | nonce);
                slotVal |= ((((1<<pricesBitsSize) - 1) << (213 - pricesBitsSize) & word) >> 4);
                refs[slot >> 248] = slotVal;

                bitIndex += pricesBitsSize;

                ptr = bitIndex >> 3;
                assembly {
                    word := shl(sub(bitIndex, shl(3, ptr)), calldataload(ptr))
                    slot := and(word, slotMask)
                    bitIndex := add(bitIndex, 8)
                    ptr := shr(3, bitIndex)

                    word := shl(sub(bitIndex, shl(3, ptr)), calldataload(ptr))
                    time := and(word, timeMask)
                    nonce := and(word, nonceMask)
                    bitIndex := add(bitIndex, 43) // 32 + 11
                }
            }
        }
    }

    function getPriceFromTick(uint256 x) public view returns(uint256 y) {
        unchecked {
            y = 79228162514264337593543950336;
            if (x & 0x1 != 0) y = (y * 79236085330515764027303304731) >> 96;
            if (x & 0x2 != 0) y = (y * 79244008939048815603706035061) >> 96;
            if (x & 0x4 != 0) y = (y * 79259858533276714757314932305) >> 96;
            if (x & 0x8 != 0) y = (y * 79291567232598584799939703904) >> 96;
            if (x & 0x10 != 0) y = (y * 79355022692464371645785046466) >> 96;
            if (x & 0x20 != 0) y = (y * 79482085999252804386437311141) >> 96;
            if (x & 0x40 != 0) y = (y * 79736823300114093921829183326) >> 96;
            if (x & 0x80 != 0) y = (y * 80248749790819932309965073892) >> 96;
            if (x & 0x100 != 0) y = (y * 81282483887344747381513967011) >> 96;
            if (x & 0x200 != 0) y = (y * 83390072131320151908154831281) >> 96;
            if (x & 0x400 != 0) y = (y * 87770609709833776024991924138) >> 96;
            if (x & 0x800 != 0) y = (y * 97234110755111693312479820773) >> 96;
            if (x & 0x1000 != 0) y = (y * 119332217159966728226237229890) >> 96;
            if (x & 0x2000 != 0) y = (y * 179736315981702064433883588727) >> 96;
            if (x & 0x4000 != 0) y = (y * 407748233172238350107850275304) >> 96;
            if (x & 0x8000 != 0) y = (y * 2098478828474011932436660412517) >> 96;
            if (x & 0x10000 != 0) y = (y * 55581415166113811149459800483533) >> 96;
            if (x & 0x20000 != 0) y = (y * 38992368544603139932233054999993551) >> 96;
            if (x & 0x40000 != 0) { y = 79228162514264337593543950336000000000000000000 / y; } else { y = y * 1e18 / 79228162514264337593543950336; }
        }
    }

    function _getRefData(uint256 symbol) public view returns (uint256 rate, uint256 lastUpdate) {
        // > 9999 is USD
        if (symbol > 9999) {
            return (1e9, block.timestamp);
        }
        uint256 refData = refs[symbol / 11];
        uint256 index = symbol % 11;
        uint256 position = (10 - index)*19;
        rate = getPriceFromTick(((((1<<19) - 1) << position) & refData) >> position);
        lastUpdate = (refData & timeMask) >> 224;
    }

}
