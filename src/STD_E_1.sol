// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import "forge-std/Test.sol";

contract STD_E_1 {

    uint256 constant private timeMask      = 0xfffffffc00000000000000000000000000000000000000000000000000000000;
    uint256 constant private slotMask      = 0xff00000000000000000000000000000000000000000000000000000000000000;
    uint256 constant private nonceMask     = 0x00f0000000000000000000000000000000000000000000000000000000000000;
    uint256 constant private indexesMask   = 0x000fe00000000000000000000000000000000000000000000000000000000000;
    uint256 constant private resetTimeMask = 0xffffffffff00007ffff00007ffff00007ffff00007ffff00007ffff00007ffff;

    uint256 constant private pt1Mask = 0xffffffffff000000000fffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant private pt2Mask = 0xfffffffffffffffffff000000000ffffffffffffffffffffffffffffffffffff;
    uint256 constant private pt3Mask = 0xffffffffffffffffffffffffffff000000000fffffffffffffffffffffffffff;
    uint256 constant private pt4Mask = 0xfffffffffffffffffffffffffffffffffffff000000000ffffffffffffffffff;
    uint256 constant private pt5Mask = 0xffffffffffffffffffffffffffffffffffffffffffffff000000000fffffffff;
    uint256 constant private pt6Mask = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000;

    struct TimeFracAndPrice {
        uint24 timeFrac;
        uint24 price;
    }

    struct Slot {
        uint32 time;
        uint8 nonce;
        uint8 mask;
        TimeFracAndPrice pt1;
        TimeFracAndPrice pt2;
        TimeFracAndPrice pt3;
        TimeFracAndPrice pt4;
        TimeFracAndPrice pt5;
        TimeFracAndPrice pt6;
    }

    // storage
    // 30|8|(19+17)*6|
    mapping(uint256 => uint256) public refs;

    function decodeSlot(uint256 slotID) public view returns(Slot memory s) {
        uint256 x = refs[slotID];
        s.time = uint32((x & (2**30 - 1) << 226) >> 226);
        s.nonce = uint8((x & (2**4 - 1) << 222) >> 222);
        s.mask = uint8((x & (2**6 - 1) << 216) >> 216);
        uint256 offset = 199;
        s.pt1.timeFrac = uint24((x & (2**17 - 1) << (offset - (36*0)) ) >> (offset - (36*0)));
        s.pt1.price = uint24((x & (2**19 - 1) << (offset - 19 - (36*0))) >> (offset - 19 - (36*0)));

        s.pt2.timeFrac = uint24((x & (2**17 - 1) << (offset - (36*1)) ) >> (offset - (36*1)));
        s.pt2.price = uint24((x & (2**19 - 1) << (offset - 19 - (36*1))) >> (offset - 19 - (36*1)));

        s.pt3.timeFrac = uint24((x & (2**17 - 1) << (offset - (36*2)) ) >> (offset - (36*2)));
        s.pt3.price = uint24((x & (2**19 - 1) << (offset - 19 - (36*2))) >> (offset - 19 - (36*2)));

        s.pt4.timeFrac = uint24((x & (2**17 - 1) << (offset - (36*3)) ) >> (offset - (36*3)));
        s.pt4.price = uint24((x & (2**19 - 1) << (offset - 19 - (36*3))) >> (offset - 19 - (36*3)));

        s.pt5.timeFrac = uint24((x & (2**17 - 1) << (offset - (36*4)) ) >> (offset - (36*4)));
        s.pt5.price = uint24((x & (2**19 - 1) << (offset - 19 - (36*4))) >> (offset - 19 - (36*4)));

        s.pt6.timeFrac = uint24((x & (2**17 - 1) << (offset - (36*5)) ) >> (offset - (36*5)));
        s.pt6.price = uint24((x & (2**19 - 1) << (offset - 19 - (36*5))) >> (offset - 19 - (36*5)));
    }

    // calldata
    // 30|(8|4|7|19{1,6})*
    function relay0JqUC4ht0CQz() public {
        uint256 ptr = 4;
        uint256 word;
        uint256 time;
        uint256 slot;
        uint256 nonce;
        uint256 idxs;
        assembly {
            word := calldataload(ptr)
            time := and(word, timeMask)
            word := shl(30, word)
            slot := and(word, slotMask)
            nonce := and(word, nonceMask)
            idxs := and(word, indexesMask)
        }
        uint256 bitIndex = 81; // 32 + 30 + 8 + 4 + 7

        require(idxs > 0, "invalid idxs");

        while (true) {
            unchecked {
                if (idxs == 0) { break; }

                uint256 slotVal = refs[slot >> 248];

                // TODO slotVal & timeMask < time
                require(0 < time, "invalid time");
                // TODO ((slotVal & nonceMask) + (1<<222)) & nonceMask == nonce
                require(0 < nonce, "invalid nonce");

                slotVal = time | (nonce >> 22) | ((idxs >> 21) & 63 << 216);
                slotVal &= resetTimeMask;

                uint256 count = 0;
                if (idxs & 1<<242 != 0) { slotVal |= ((((1<<19) - 1) << (218 - count)) & word) >> 38; count += 19; } // 218 - (19+17)*5 - count
                if (idxs & 1<<241 != 0) { slotVal |= ((((1<<19) - 1) << (218 - count)) & word) >> (74 - count); count += 19; } // 218 - (19+17)*4 - count
                if (idxs & 1<<240 != 0) { slotVal |= ((((1<<19) - 1) << (218 - count)) & word) >> (110 - count); count += 19; } // 218 - (19+17)*3 - count
                if (idxs & 1<<239 != 0) { slotVal |= ((((1<<19) - 1) << (218 - count)) & word) >> (146 - count); count += 19; } // 218 - (19+17)*2 - count
                if (idxs & 1<<238 != 0) { slotVal |= ((((1<<19) - 1) << (218 - count)) & word) >> (182 - count); count += 19; } // 218 - (19+17)*1 - count
                if (idxs & 1<<237 != 0) { slotVal |= ((((1<<19) - 1) << (218 - count)) & word) >> (218 - count); count += 19; } // 218 - (19+17)*0 - count
                bitIndex += count;

                refs[slot >> 248] = slotVal;

                if (idxs < 1<<243) { break; }

                ptr = (bitIndex >> 3);
                assembly {
                    word := shl(sub(bitIndex, shl(3, ptr)), calldataload(ptr))
                    slot := and(word, slotMask)
                    nonce := and(word, nonceMask)
                    idxs := and(word, indexesMask)
                    bitIndex := add(bitIndex, 19) // 8 + 4 + 7
                }
            }
        }
    }

    // calldata
    // price deviated less than 10.77 %
    // (8|4|7|(17+11){1,6})*
    function relay1GsWnfsIQROy() public {
        // uint256 g = gasleft();
        uint256 ptr = 4;
        uint256 word;
        uint256 slot;
        uint256 nonce;
        uint256 idxs;
        assembly {
            word := calldataload(ptr)
            slot := and(word, slotMask)
            nonce := and(word, nonceMask)
            idxs := and(word, indexesMask)
        }
        uint256 bitIndex = 51; // 32 + 8 + 4 + 7

        require(idxs > 0, "invalid idxs");

        while (true) {
            unchecked {
                uint256 slotVal = refs[slot >> 248];

                // TODO ((slotVal & nonceMask) + (1<<222)) & nonceMask == nonce
                // require(0 < nonce, "invalid nonce");

                uint256 count = 0;
                if (idxs & 1<<242 != 0) {
                    uint256 timeFracOld = slotVal & (((1<<17) - 1) << 199);
                    uint256 timeFracNew = (word & (((1<<17) - 1) << 220)) >> 21;

                    // TODO timeFracNew > timeFracOld
                    require(timeFracNew > 0, "Invalid timeFracNew");

                    uint256 currentPrice = slotVal & (((1<<19) - 1) << 180);
                    uint256 diffPrice = (word & (((1<<11) - 1) << 209)) >> 29;

                    if (diffPrice & (1<<190) != 0) { currentPrice = (currentPrice - diffPrice) & (((1<<19) - 1) << 180); }
                    else { currentPrice = (currentPrice + diffPrice) & (((1<<19) - 1) << 180); }

                    slotVal = (slotVal & pt1Mask) | timeFracNew | currentPrice;

                    count += 28;
                }
                if (idxs & 1<<241 != 0) {
                    uint256 timeFracOld = slotVal & (((1<<17) - 1) << 163);
                    uint256 timeFracNew = (word & (((1<<17) - 1) << (220 - count) )) >> (57 - count);

                    // TODO timeFracNew > timeFracOld
                    require(timeFracNew > 0, "Invalid timeFracNew");

                    uint256 currentPrice = slotVal & (((1<<19) - 1) << 144);
                    uint256 diffPrice = (word & (((1<<11) - 1) << (209 - count))) >> (65 - count);

                    if (diffPrice & (1<<154) != 0) { currentPrice = (currentPrice - diffPrice) & (((1<<19) - 1) << 144); }
                    else { currentPrice = (currentPrice + diffPrice) & (((1<<19) - 1) << 144); }

                    slotVal = (slotVal & pt2Mask) | timeFracNew | currentPrice;

                    count += 28;
                }
                if (idxs & 1<<240 != 0) {
                    uint256 timeFracOld = slotVal & (((1<<17) - 1) << 127);
                    uint256 timeFracNew = (word & (((1<<17) - 1) << (220 - count) )) >> (93 - count);

                    // TODO timeFracNew > timeFracOld
                    require(timeFracNew > 0, "Invalid timeFracNew");

                    uint256 currentPrice = slotVal & (((1<<19) - 1) << 108);
                    uint256 diffPrice = (word & (((1<<11) - 1) << (209 - count))) >> (101 - count);

                    if (diffPrice & (1<<118) != 0) { currentPrice = (currentPrice - diffPrice) & (((1<<19) - 1) << 108); }
                    else { currentPrice = (currentPrice + diffPrice) & (((1<<19) - 1) << 108); }

                    slotVal = (slotVal & pt3Mask) | timeFracNew | currentPrice;

                    count += 28;
                }
                if (idxs & 1<<239 != 0) {
                    uint256 timeFracOld = slotVal & (((1<<17) - 1) << 91);
                    uint256 timeFracNew = (word & (((1<<17) - 1) << (220 - count) )) >> (129 - count);

                    // TODO timeFracNew > timeFracOld
                    require(timeFracNew > 0, "Invalid timeFracNew");

                    uint256 currentPrice = slotVal & (((1<<19) - 1) << 72);
                    uint256 diffPrice = (word & (((1<<11) - 1) << (209 - count))) >> (137 - count);

                    if (diffPrice & (1<<82) != 0) { currentPrice = (currentPrice - diffPrice) & (((1<<19) - 1) << 72); }
                    else { currentPrice = (currentPrice + diffPrice) & (((1<<19) - 1) << 72); }

                    slotVal = (slotVal & pt4Mask) | timeFracNew | currentPrice;

                    count += 28;
                }
                if (idxs & 1<<238 != 0) {
                    uint256 timeFracOld = slotVal & (((1<<17) - 1) << 55);
                    uint256 timeFracNew = (word & (((1<<17) - 1) << (220 - count) )) >> (165 - count);

                    // TODO timeFracNew > timeFracOld
                    require(timeFracNew > 0, "Invalid timeFracNew");

                    uint256 currentPrice = slotVal & (((1<<19) - 1) << 36);
                    uint256 diffPrice = (word & (((1<<11) - 1) << (209 - count))) >> (173 - count);

                    if (diffPrice & (1<<46) != 0) { currentPrice = (currentPrice - diffPrice) & (((1<<19) - 1) << 36); }
                    else { currentPrice = (currentPrice + diffPrice) & (((1<<19) - 1) << 36); }

                    slotVal = (slotVal & pt5Mask) | timeFracNew | currentPrice;

                    count += 28;
                }
                 if (idxs & 1<<237 != 0) {
                     uint256 timeFracOld = slotVal & (((1<<17) - 1) << 19);
                    uint256 timeFracNew = (word & (((1<<17) - 1) << (220 - count) )) >> (201 - count);

                    // TODO timeFracNew > timeFracOld
                    require(timeFracNew > 0, "Invalid timeFracNew");

                    uint256 currentPrice = slotVal & ((1<<19) - 1);
                    uint256 diffPrice = (word & (((1<<11) - 1) << (209 - count))) >> (209 - count);

                    if (diffPrice & (1<<10) != 0) { currentPrice = (currentPrice - diffPrice) & ((1<<19) - 1); }
                    else { currentPrice = (currentPrice + diffPrice) & ((1<<19) - 1); }

                    slotVal = (slotVal & pt6Mask) | timeFracNew | currentPrice;

                    count += 28;
                }

                bitIndex += count;

                refs[slot >> 248] = slotVal;

                if (idxs < 64) {
                    break;
                }

                ptr = (bitIndex >> 3);
                assembly {
                    word := shl(sub(bitIndex, shl(3, ptr)), calldataload(ptr))
                    slot := and(word, slotMask)
                    nonce := and(word, nonceMask)
                    idxs := and(word, indexesMask)
                    bitIndex := add(bitIndex, 19) // 8 + 4 + 7
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
        uint256 refData = refs[symbol / 6];
        uint256 index = symbol % 6;
        uint256 position = (5 - index)*36;
        rate = getPriceFromTick(((((1<<19) - 1) << position) & refData) >> position);
        lastUpdate = (refData & timeMask) >> 226;
    }

}
