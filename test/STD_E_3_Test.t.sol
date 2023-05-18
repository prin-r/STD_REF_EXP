// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/STD_E_3.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";


contract STD_E_2_Test is Test {
    uint256 public constant MOCK_REQ_ID = 999999;
    STD_E_3 public std3;

    struct TimeOffsetAndPrice {
        uint256 timeOffset;
        uint256 ticks;
        string symbol;
    }

    struct Slot {
        uint256 time;
        uint256 symbolsCount;
        TimeOffsetAndPrice tp1;
        TimeOffsetAndPrice tp2;
        TimeOffsetAndPrice tp3;
        TimeOffsetAndPrice tp4;
        TimeOffsetAndPrice tp5;
        TimeOffsetAndPrice tp6;
    }

    function setUp() public {
        address std3Impl = address(new STD_E_3());
        address proxyAdmin = address(new ProxyAdmin());
        std3 = STD_E_3(address(new TransparentUpgradeableProxy(std3Impl, proxyAdmin, bytes(""))));
        std3.initialize();
    }

    function isEqStr(string memory s1, string memory s2) private pure returns(bool) {
        return keccak256(bytes(s1)) == keccak256(bytes(s2));
    }

    function tapsToPS(TimeOffsetAndPrice[] memory taps) private pure returns(STD_E_3.Price[] memory ps) {
        ps = new STD_E_3.Price[](taps.length);
        for (uint256 i = 0; i < taps.length; i++) {
            ps[i] = STD_E_3.Price(taps[i].ticks, taps[i].symbol);
        }
    }

    function decodeSlot(uint256 slotID) private view returns(Slot memory s) {
        uint256 x = std3.refs(slotID);
        s.time = (x & (((1<<31) - 1) << 225)) >> 225;
        s.symbolsCount = (x & (((1<<3) - 1) << 222)) >> 222;

        uint256 offset = 204; // 222 - 18
        s.tp1.timeOffset = (x & ((2**18 - 1) << (offset - (37*0)))) >> (offset - (37*0));
        s.tp1.ticks = (x & ((2**19 - 1) << (offset - 19 - (37*0)))) >> (offset - 19 - (37*0));
        s.tp1.symbol = std3.idsToSymbols(slotID*6 + 1);

        s.tp2.timeOffset = (x & ((2**18 - 1) << (offset - (37*1)))) >> (offset - (37*1));
        s.tp2.ticks = (x & ((2**19 - 1) << (offset - 19 - (37*1)))) >> (offset - 19 - (37*1));
        s.tp2.symbol = std3.idsToSymbols(slotID*6 + 2);

        s.tp3.timeOffset = (x & ((2**18 - 1) << (offset - (37*2)))) >> (offset - (37*2));
        s.tp3.ticks = (x & ((2**19 - 1) << (offset - 19 - (37*2)))) >> (offset - 19 - (37*2));
        s.tp3.symbol = std3.idsToSymbols(slotID*6 + 3);

        s.tp4.timeOffset = (x & ((2**18 - 1) << (offset - (37*3)))) >> (offset - (37*3));
        s.tp4.ticks = (x & ((2**19 - 1) << (offset - 19 - (37*3)))) >> (offset - 19 - (37*3));
        s.tp4.symbol = std3.idsToSymbols(slotID*6 + 4);

        s.tp5.timeOffset = (x & ((2**18 - 1) << (offset - (37*4)))) >> (offset - (37*4));
        s.tp5.ticks = (x & ((2**19 - 1) << (offset - 19 - (37*4)))) >> (offset - 19 - (37*4));
        s.tp5.symbol = std3.idsToSymbols(slotID*6 + 5);

        s.tp6.timeOffset = (x & ((2**18 - 1) << (offset - (37*5)))) >> (offset - (37*5));
        s.tp6.ticks = (x & ((2**19 - 1) << (offset - 19 - (37*5)))) >> (offset - 19 - (37*5));
        s.tp6.symbol = std3.idsToSymbols(slotID*6 + 6);
    }

    function printSlot(uint256 x) private view {
        Slot memory s = decodeSlot(x);
        console.log("=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
        console.log("(time, count):  ", s.time, s.symbolsCount);
        console.log("(ticks1, time1, symbol1): ", s.tp1.ticks, s.tp1.timeOffset, s.tp1.symbol);
        console.log("(ticks2, time2, symbol2): ", s.tp2.ticks, s.tp2.timeOffset, s.tp2.symbol);
        console.log("(ticks3, time3, symbol3): ", s.tp3.ticks, s.tp3.timeOffset, s.tp3.symbol);
        console.log("(ticks4, time4, symbol4): ", s.tp4.ticks, s.tp4.timeOffset, s.tp4.symbol);
        console.log("(ticks5, time5, symbol5): ", s.tp5.ticks, s.tp5.timeOffset, s.tp5.symbol);
        console.log("(ticks6, time6, symbol6): ", s.tp6.ticks, s.tp6.timeOffset, s.tp6.symbol);
        console.log("=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
    }

    function testGetPriceFromTick() public {
        vm.expectRevert("FAIL_TICKS_0_IS_AN_EMPTY_PRICE");
        std3.getPriceFromTick(0);

        assertEq(std3.getPriceFromTick(1), 4128985);
        assertEq(std3.getPriceFromTick(10), 4132703);
        assertEq(std3.getPriceFromTick(100), 4170063);
        assertEq(std3.getPriceFromTick(1000), 4562755);
        assertEq(std3.getPriceFromTick(10000), 11222063);
        assertEq(std3.getPriceFromTick(100000), 90892410323);
        assertEq(std3.getPriceFromTick(262144), 1000000000000000000);
        assertEq(std3.getPriceFromTick(300000), 44053761159937252819);
        assertEq(std3.getPriceFromTick(400000), 969863642590014515135770);
        assertEq(std3.getPriceFromTick(524287), 242190240580283037346837115381);
    }

    function testListingAnddelisting() public {
        string[] memory symbols = new string[](1);
        symbols[0] = "BTC";
        std3.listing(symbols);
        assertEq(std3.symbolsToIDs(symbols[0]), 1);
        assertEq(std3.totalSymbolsCount(), 1);

        symbols = new string[](12);
        symbols[0] = "ETH";
        symbols[1] = "BNB";
        symbols[2] = "ADA";
        symbols[3] = "DOGE";
        symbols[4] = "XRP";
        symbols[5] = "DOT";
        symbols[6] = "SOL";
        symbols[7] = "UNI";
        symbols[8] = "LINK";
        symbols[9] = "SNX";
        symbols[10] = "DAI";
        symbols[11] = "SNX2";
        std3.listing(symbols);
        for (uint256 i = 0; i < 12; i++) assertEq(std3.symbolsToIDs(symbols[i]), i+2);
        assertEq(std3.totalSymbolsCount(), 13);

        symbols = new string[](5);
        symbols[0] = "BAND";
        symbols[1] = "ALPHA";
        symbols[2] = "BETA";
        symbols[3] = "USDC";
        symbols[4] = "SUSD";
        std3.listing(symbols);
        for (uint256 i = 0; i < 5; i++) assertEq(std3.symbolsToIDs(symbols[i]), i+14);
        assertEq(std3.totalSymbolsCount(), 18);

        symbols = new string[](4);
        symbols[0] = "AA1";
        symbols[1] = "AA2";
        symbols[2] = "AA3";
        symbols[3] = "AA4";
        std3.listing(symbols);
        for (uint256 i = 0; i < 4; i++) assertEq(std3.symbolsToIDs(symbols[i]), i+19);
        assertEq(std3.totalSymbolsCount(), 22);

        symbols = new string[](1);
        symbols[0] = "AA5";
        std3.listing(symbols);
        assertEq(std3.symbolsToIDs(symbols[0]), 23);
        assertEq(std3.totalSymbolsCount(), 23);

        symbols = new string[](3);
        symbols[0] = "AA6";
        symbols[1] = "AA7";
        symbols[2] = "AA8";
        std3.listing(symbols);
        for (uint256 i = 0; i < 3; i++) assertEq(std3.symbolsToIDs(symbols[i]), i+24);
        assertEq(std3.totalSymbolsCount(), 26);

        symbols = new string[](1);
        symbols[0] = "AA9";
        std3.listing(symbols);
        assertEq(std3.symbolsToIDs(symbols[0]), 27);
        assertEq(std3.totalSymbolsCount(), 27);

        // ------------------------------------------------------------------

        symbols = new string[](1);
        symbols[0] = "BAND";
        std3.delisting(symbols);
        assertEq(std3.totalSymbolsCount(), 26);

        symbols = new string[](2);
        symbols[0] = "BETA";
        symbols[1] = "USDC";
        std3.delisting(symbols);
        assertEq(std3.totalSymbolsCount(), 24);

        symbols = new string[](1);
        symbols[0] = "BTC";
        std3.delisting(symbols);
        assertEq(std3.totalSymbolsCount(), 23);

        symbols = new string[](23);
        symbols[0] = "AA6";
        symbols[1] = "ETH";
        symbols[2] = "BNB";
        symbols[3] = "ADA";
        symbols[4] = "DOGE";
        symbols[5] = "XRP";
        symbols[6] = "DOT";
        symbols[7] = "SOL";
        symbols[8] = "UNI";
        symbols[9] = "LINK";
        symbols[10] = "SNX";
        symbols[11] = "DAI";
        symbols[12] = "SNX2";
        symbols[13] = "AA9";
        symbols[14] = "ALPHA";
        symbols[15] = "AA8";
        symbols[16] = "AA7";
        symbols[17] = "SUSD";
        symbols[18] = "AA1";
        symbols[19] = "AA2";
        symbols[20] = "AA3";
        symbols[21] = "AA4";
        symbols[22] = "AA5";
        for (uint256 i = 0; i < 23; i++) assertEq(symbols[i], std3.idsToSymbols(i+1));

        symbols = new string[](10);
        symbols[0] = "DOT";
        symbols[1] = "SOL";
        symbols[2] = "BNB";
        symbols[3] = "ADA";
        symbols[4] = "DOGE";
        symbols[5] = "XRP";
        symbols[6] = "AA5";
        symbols[7] = "SUSD";
        symbols[8] = "ALPHA";
        symbols[9] = "AA8";
        std3.delisting(symbols);
        assertEq(std3.totalSymbolsCount(), 13);

        symbols = new string[](13);
        symbols[0] = "AA6";
        symbols[1] = "ETH";
        symbols[2] = "AA3";
        symbols[3] = "AA2";
        symbols[4] = "AA1";
        symbols[5] = "AA9";
        symbols[6] = "AA7";
        symbols[7] = "AA4";
        symbols[8] = "UNI";
        symbols[9] = "LINK";
        symbols[10] = "SNX";
        symbols[11] = "DAI";
        symbols[12] = "SNX2";
        for (uint256 i = 0; i < 13; i++) assertEq(symbols[i], std3.idsToSymbols(i+1));

        symbols = new string[](13);
        symbols[0] = "AA1";
        symbols[1] = "AA2";
        symbols[2] = "AA3";
        symbols[3] = "AA4";
        symbols[4] = "AA6";
        symbols[5] = "AA7";
        symbols[6] = "AA9";
        symbols[7] = "DAI";
        symbols[8] = "ETH";
        symbols[9] = "LINK";
        symbols[10] = "SNX";
        symbols[11] = "SNX2";
        symbols[12] = "UNI";
        std3.delisting(symbols);
        assertEq(std3.totalSymbolsCount(), 0);
    }

    function testRelay() public {
        string[] memory symbols = new string[](13);
        symbols[0] = "ETH";
        symbols[1] = "BNB";
        symbols[2] = "ADA";
        symbols[3] = "BTC";
        symbols[4] = "XRP";
        symbols[5] = "DOT";
        symbols[6] = "SOL";
        symbols[7] = "UNI";
        symbols[8] = "LINK";
        symbols[9] = "SNX";
        symbols[10] = "DAI";
        symbols[11] = "DOGE";
        symbols[12] = "BAND";
        std3.listing(symbols);

        STD_E_3.Price[] memory ps = new STD_E_3.Price[](4);
        ps[0] = STD_E_3.Price(100, "BTC");
        ps[1] = STD_E_3.Price(200, "ETH");
        ps[2] = STD_E_3.Price(300, "DAI");
        ps[3] = STD_E_3.Price(400, "DOGE");
        std3.relay(555, MOCK_REQ_ID, ps);
        for (uint256 i = 0; i < 4; i++) {
            (uint256 ticks, uint256 lastUpdated) = std3.getTicksAndTime(ps[i].symbol);
            assertEq(ticks, ps[i].ticks);
            assertEq(lastUpdated, 555);
        }

        ps[0] = STD_E_3.Price(888, "BTC");
        ps[1] = STD_E_3.Price(666, "ETH");
        ps[2] = STD_E_3.Price(444, "DAI");
        ps[3] = STD_E_3.Price(222, "DOGE");
        std3.relay(1111, MOCK_REQ_ID, ps);
        for (uint256 i = 0; i < 4; i++) {
            (uint256 ticks, uint256 lastUpdated) = std3.getTicksAndTime(ps[i].symbol);
            assertEq(ticks, ps[i].ticks);
            assertEq(lastUpdated, 1111);
        }

        ps = new STD_E_3.Price[](9);
        ps[0] = STD_E_3.Price(101, "BNB");
        ps[1] = STD_E_3.Price(104, "ADA");
        ps[2] = STD_E_3.Price(109, "XRP");
        ps[3] = STD_E_3.Price(116, "DOT");
        ps[4] = STD_E_3.Price(125, "SOL");
        ps[5] = STD_E_3.Price(136, "UNI");
        ps[6] = STD_E_3.Price(149, "LINK");
        ps[7] = STD_E_3.Price(164, "SNX");
        ps[8] = STD_E_3.Price(181, "BAND");
        std3.relay(123, MOCK_REQ_ID, ps);

        // check all
        TimeOffsetAndPrice[] memory taps = new TimeOffsetAndPrice[](13);
        taps[0] = TimeOffsetAndPrice(123, 101, "BNB");
        taps[1] = TimeOffsetAndPrice(123, 104, "ADA");
        taps[2] = TimeOffsetAndPrice(123, 109, "XRP");
        taps[3] = TimeOffsetAndPrice(123, 116, "DOT");
        taps[4] = TimeOffsetAndPrice(123, 125, "SOL");
        taps[5] = TimeOffsetAndPrice(123, 136, "UNI");
        taps[6] = TimeOffsetAndPrice(123, 149, "LINK");
        taps[7] = TimeOffsetAndPrice(123, 164, "SNX");
        taps[8] = TimeOffsetAndPrice(123, 181, "BAND");
        taps[9] = TimeOffsetAndPrice(1111, 888, "BTC");
        taps[10] = TimeOffsetAndPrice(1111, 666, "ETH");
        taps[11] = TimeOffsetAndPrice(1111, 444, "DAI");
        taps[12] = TimeOffsetAndPrice(1111, 222, "DOGE");
        for (uint256 i = 0; i < 13; i++) {
            (uint256 ticks, uint256 lastUpdated) = std3.getTicksAndTime(taps[i].symbol);
            assertEq(ticks, taps[i].ticks);
            assertEq(lastUpdated, taps[i].timeOffset);
        }
    }

    function testRelayRebase() public {
        string[] memory symbols = new string[](13);
        symbols[0] = "ETH";
        symbols[1] = "BNB";
        symbols[2] = "ADA";
        symbols[3] = "BTC";
        symbols[4] = "XRP";
        symbols[5] = "DOT";
        symbols[6] = "SOL";
        symbols[7] = "UNI";
        symbols[8] = "LINK";
        symbols[9] = "SNX";
        symbols[10] = "DAI";
        symbols[11] = "DOGE";
        symbols[12] = "BAND";
        std3.listing(symbols);

        STD_E_3.Price[] memory ps = new STD_E_3.Price[](6);
        ps[0] = STD_E_3.Price(100, "ETH");
        ps[1] = STD_E_3.Price(200, "BNB");
        ps[2] = STD_E_3.Price(300, "ADA");
        ps[3] = STD_E_3.Price(400, "BTC");
        ps[4] = STD_E_3.Price(500, "XRP");
        ps[5] = STD_E_3.Price(600, "DOT");
        std3.relayRebase(999, MOCK_REQ_ID, ps);
        for (uint256 i = 0; i < 6; i++) {
            (uint256 ticks, uint256 lastUpdated) = std3.getTicksAndTime(ps[i].symbol);
            assertEq(ticks, ps[i].ticks);
            assertEq(lastUpdated, 999);
        }

        ps[0] = STD_E_3.Price(110, "SOL");
        ps[1] = STD_E_3.Price(210, "UNI");
        ps[2] = STD_E_3.Price(310, "LINK");
        ps[3] = STD_E_3.Price(410, "SNX");
        ps[4] = STD_E_3.Price(510, "DAI");
        ps[5] = STD_E_3.Price(610, "DOGE");
        std3.relayRebase(1888, MOCK_REQ_ID, ps);

        ps = new STD_E_3.Price[](12);
        ps[0] = STD_E_3.Price(100, "ETH");
        ps[1] = STD_E_3.Price(200, "BNB");
        ps[2] = STD_E_3.Price(300, "ADA");
        ps[3] = STD_E_3.Price(400, "BTC");
        ps[4] = STD_E_3.Price(500, "XRP");
        ps[5] = STD_E_3.Price(600, "DOT");
        ps[6] = STD_E_3.Price(110, "SOL");
        ps[7] = STD_E_3.Price(210, "UNI");
        ps[8] = STD_E_3.Price(310, "LINK");
        ps[9] = STD_E_3.Price(410, "SNX");
        ps[10] = STD_E_3.Price(510, "DAI");
        ps[11] = STD_E_3.Price(610, "DOGE");
        for (uint256 i = 0; i < 12; i++) {
            (uint256 ticks, uint256 lastUpdated) = std3.getTicksAndTime(ps[i].symbol);
            assertEq(ticks, ps[i].ticks);
            if (i < 6) assertEq(lastUpdated, 999);
            else assertEq(lastUpdated, 1888);
        }

        ps = new STD_E_3.Price[](13);
        ps[0] = STD_E_3.Price(100, "ETH");
        ps[1] = STD_E_3.Price(200, "BNB");
        ps[2] = STD_E_3.Price(300, "ADA");
        ps[3] = STD_E_3.Price(400, "BTC");
        ps[4] = STD_E_3.Price(500, "XRP");
        ps[5] = STD_E_3.Price(600, "DOT");
        ps[6] = STD_E_3.Price(110, "SOL");
        ps[7] = STD_E_3.Price(210, "UNI");
        ps[8] = STD_E_3.Price(310, "LINK");
        ps[9] = STD_E_3.Price(410, "SNX");
        ps[10] = STD_E_3.Price(510, "DAI");
        ps[11] = STD_E_3.Price(610, "DOGE");
        ps[12] = STD_E_3.Price(710, "BAND");
        std3.relayRebase(3333, MOCK_REQ_ID, ps);

        for (uint256 i = 0; i < 13; i++) {
            (uint256 ticks, uint256 lastUpdated) = std3.getTicksAndTime(ps[i].symbol);
            assertEq(ticks, ps[i].ticks);
            assertEq(lastUpdated, 3333);
        }
    }

    function testRelayAndRelayRebase() public {
        string[] memory symbols = new string[](23);
        symbols[0] = "AA6";
        symbols[1] = "ETH";
        symbols[2] = "BNB";
        symbols[3] = "ADA";
        symbols[4] = "DOGE";
        symbols[5] = "XRP";
        symbols[6] = "DOT";
        symbols[7] = "SOL";
        symbols[8] = "UNI";
        symbols[9] = "LINK";
        symbols[10] = "SNX";
        symbols[11] = "DAI";
        symbols[12] = "SNX2";
        symbols[13] = "AA9";
        symbols[14] = "ALPHA";
        symbols[15] = "AA8";
        symbols[16] = "AA7";
        symbols[17] = "SUSD";
        symbols[18] = "AA1";
        symbols[19] = "AA2";
        symbols[20] = "AA3";
        symbols[21] = "AA4";
        symbols[22] = "AA5";
        std3.listing(symbols);

        symbols = new string[](6);
        symbols[0] = "UNI";
        symbols[1] = "SOL";
        symbols[2] = "AA8";
        symbols[3] = "SUSD";
        symbols[4] = "ALPHA";
        symbols[5] = "DOGE";
        std3.delisting(symbols);

        symbols = new string[](17);
        symbols[0] = "AA6";
        symbols[1] = "ETH";
        symbols[2] = "BNB";
        symbols[3] = "ADA";
        symbols[4] = "AA2";
        symbols[5] = "XRP";
        symbols[6] = "DOT";
        symbols[7] = "AA4";
        symbols[8] = "AA5";
        symbols[9] = "LINK";
        symbols[10] = "SNX";
        symbols[11] = "DAI";
        symbols[12] = "SNX2";
        symbols[13] = "AA9";
        symbols[14] = "AA1";
        symbols[15] = "AA3";
        symbols[16] = "AA7";
        assertEq(std3.totalSymbolsCount(), 17);
        for (uint256 i = 0; i < 17; i++) assertEq(std3.symbolsToIDs(symbols[i]), i + 1);

        // -----------------------------------------------------------------------------

        STD_E_3.Price[] memory ps = new STD_E_3.Price[](17);
        ps[0] = STD_E_3.Price(272100, "AA6");
        ps[1] = STD_E_3.Price(272200, "ETH");
        ps[2] = STD_E_3.Price(272300, "BNB");
        ps[3] = STD_E_3.Price(272400, "ADA");
        ps[4] = STD_E_3.Price(272500, "AA2");
        ps[5] = STD_E_3.Price(272600, "XRP");
        ps[6] = STD_E_3.Price(272110, "DOT");
        ps[7] = STD_E_3.Price(272210, "AA4");
        ps[8] = STD_E_3.Price(272310, "AA5");
        ps[9] = STD_E_3.Price(272410, "LINK");
        ps[10] = STD_E_3.Price(272510, "SNX");
        ps[11] = STD_E_3.Price(272610, "DAI");
        ps[12] = STD_E_3.Price(273710, "SNX2");
        ps[13] = STD_E_3.Price(274710, "AA9");
        ps[14] = STD_E_3.Price(275710, "AA1");
        ps[15] = STD_E_3.Price(276710, "AA3");
        ps[16] = STD_E_3.Price(277710, "AA7");
        std3.relayRebase(1684100000, MOCK_REQ_ID, ps);
        for (uint256 i = 0; i < 17; i++) {
            (uint256 ticks, uint256 lastUpdated) = std3.getTicksAndTime(ps[i].symbol);
            assertEq(ticks, ps[i].ticks);
            assertEq(lastUpdated, 1684100000);
        }

        ps = new STD_E_3.Price[](9);
        ps[0] = STD_E_3.Price(303030, "DOT");
        ps[1] = STD_E_3.Price(304440, "ADA");
        ps[2] = STD_E_3.Price(305530, "AA2");
        ps[3] = STD_E_3.Price(306660, "AA4");
        ps[4] = STD_E_3.Price(307770, "AA5");
        ps[5] = STD_E_3.Price(310030, "XRP");
        ps[6] = STD_E_3.Price(320030, "DAI");
        ps[7] = STD_E_3.Price(330030, "SNX");
        ps[8] = STD_E_3.Price(355550, "ETH");
        std3.relay(1684100112, MOCK_REQ_ID, ps);

        ps = new STD_E_3.Price[](9);
        ps[0] = STD_E_3.Price(283030, "AA6");
        ps[1] = STD_E_3.Price(284440, "LINK");
        ps[2] = STD_E_3.Price(285530, "BNB");
        ps[3] = STD_E_3.Price(286660, "AA7");
        ps[4] = STD_E_3.Price(287770, "AA3");
        ps[5] = STD_E_3.Price(290030, "AA1");
        ps[6] = STD_E_3.Price(290040, "AA9");
        ps[7] = STD_E_3.Price(290050, "SNX2");
        ps[8] = STD_E_3.Price(295550, "ETH");
        std3.relay(1684100222, MOCK_REQ_ID, ps);

        TimeOffsetAndPrice[] memory taps = new TimeOffsetAndPrice[](17);
        taps[0] = TimeOffsetAndPrice(1684100222, 283030, "AA6");
        taps[1] = TimeOffsetAndPrice(1684100222, 284440, "LINK");
        taps[2] = TimeOffsetAndPrice(1684100222, 285530, "BNB");
        taps[3] = TimeOffsetAndPrice(1684100222, 286660, "AA7");
        taps[4] = TimeOffsetAndPrice(1684100222, 287770, "AA3");
        taps[5] = TimeOffsetAndPrice(1684100222, 290030, "AA1");
        taps[6] = TimeOffsetAndPrice(1684100222, 290040, "AA9");
        taps[7] = TimeOffsetAndPrice(1684100222, 290050, "SNX2");
        taps[8] = TimeOffsetAndPrice(1684100222, 295550, "ETH");
        taps[9] = TimeOffsetAndPrice(1684100112, 303030, "DOT");
        taps[10] = TimeOffsetAndPrice(1684100112, 304440, "ADA");
        taps[11] = TimeOffsetAndPrice(1684100112, 305530, "AA2");
        taps[12] = TimeOffsetAndPrice(1684100112, 306660, "AA4");
        taps[13] = TimeOffsetAndPrice(1684100112, 307770, "AA5");
        taps[14] = TimeOffsetAndPrice(1684100112, 310030, "XRP");
        taps[15] = TimeOffsetAndPrice(1684100112, 320030, "DAI");
        taps[16] = TimeOffsetAndPrice(1684100112, 330030, "SNX");
        for (uint256 i = 0; i < 17; i++) {
            (uint256 ticks, uint256 lastUpdated) = std3.getTicksAndTime(taps[i].symbol);
            assertEq(ticks, taps[i].ticks);
            assertEq(lastUpdated, taps[i].timeOffset);
        }

        assertEq(std3.maxTimeOffset(0), 222);
        assertEq(std3.maxTimeOffset(1), 222);
        assertEq(std3.maxTimeOffset(2), 222);

        symbols = new string[](2);
        symbols[0] = "DOT";
        symbols[1] = "AA6";
        std3.delisting(symbols);

        for (uint256 i = 0; i < 17; i++) {
            if (isEqStr(taps[i].symbol, "DOT") || isEqStr(taps[i].symbol, "AA6")) {
                vm.expectRevert("FAIL_SYMBOL_NOT_AVAILABLE");
                std3.getTicksAndTime(taps[i].symbol);
            } else {
                (uint256 ticks, uint256 lastUpdated) = std3.getTicksAndTime(taps[i].symbol);
                assertEq(ticks, taps[i].ticks);
                assertEq(lastUpdated, taps[i].timeOffset);
            }
        }

        symbols = new string[](8);
        symbols[0] = "AA7";
        symbols[1] = "LINK";
        symbols[2] = "AA9";
        symbols[3] = "AA2";
        symbols[4] = "AA5";
        symbols[5] = "AA4";
        symbols[6] = "AA3";
        symbols[7] = "AA1";
        std3.delisting(symbols);

        Slot memory s0 = decodeSlot(0);
        Slot memory s1 = decodeSlot(1);
        Slot memory s0Expected = Slot(
            1684100000,
            6,
            TimeOffsetAndPrice(112, 330030, "SNX"),
            TimeOffsetAndPrice(222, 295550, "ETH"),
            TimeOffsetAndPrice(222, 285530, "BNB"),
            TimeOffsetAndPrice(112, 304440, "ADA"),
            TimeOffsetAndPrice(112, 320030, "DAI"),
            TimeOffsetAndPrice(112, 310030, "XRP")
        );
        Slot memory s1Expected = Slot(
            1684100000,
            1,
            TimeOffsetAndPrice(222, 290050, "SNX2"),
            TimeOffsetAndPrice(0, 0, ""),
            TimeOffsetAndPrice(0, 0, ""),
            TimeOffsetAndPrice(0, 0, ""),
            TimeOffsetAndPrice(0, 0, ""),
            TimeOffsetAndPrice(0, 0, "")
        );

        assertEq(keccak256(abi.encode("0.", s0, "1.", s1)), keccak256(abi.encode("0.", s0Expected, "1.", s1Expected)));

        ps = new STD_E_3.Price[](7);
        ps[0] = STD_E_3.Price(300000, "SNX");
        ps[1] = STD_E_3.Price(300001, "ETH");
        ps[2] = STD_E_3.Price(300002, "BNB");
        ps[3] = STD_E_3.Price(300003, "ADA");
        ps[4] = STD_E_3.Price(300004, "DAI");
        ps[5] = STD_E_3.Price(300005, "XRP");
        ps[6] = STD_E_3.Price(300006, "SNX2");
        std3.relayRebase(1684200000, MOCK_REQ_ID, ps);

        s0 = decodeSlot(0);
        s1 = decodeSlot(1);
        s0Expected = Slot(
            1684200000,
            6,
            TimeOffsetAndPrice(0, 300000, "SNX"),
            TimeOffsetAndPrice(0, 300001, "ETH"),
            TimeOffsetAndPrice(0, 300002, "BNB"),
            TimeOffsetAndPrice(0, 300003, "ADA"),
            TimeOffsetAndPrice(0, 300004, "DAI"),
            TimeOffsetAndPrice(0, 300005, "XRP")
        );
        s1Expected = Slot(
            1684200000,
            1,
            TimeOffsetAndPrice(0, 300006, "SNX2"),
            TimeOffsetAndPrice(0, 0, ""),
            TimeOffsetAndPrice(0, 0, ""),
            TimeOffsetAndPrice(0, 0, ""),
            TimeOffsetAndPrice(0, 0, ""),
            TimeOffsetAndPrice(0, 0, "")
        );

        assertEq(keccak256(abi.encode("0.", s0, "1.", s1)), keccak256(abi.encode("0.", s0Expected, "1.", s1Expected)));
    }

    function testListing_FAIL_SYMBOLS_IS_EMPTY() public {
        string[] memory symbols = new string[](0);
        vm.expectRevert("FAIL_SYMBOLS_IS_EMPTY");
        std3.listing(symbols);
    }

    function testListing_FAIL_USD_CANT_BE_SET() public {
        string[] memory symbols = new string[](1);
        symbols[0] = "USD";
        vm.expectRevert("FAIL_USD_CANT_BE_SET");
        std3.listing(symbols);

        symbols = new string[](9);
        symbols[0] = "AA1";
        symbols[1] = "AA2";
        symbols[2] = "AA3";
        symbols[3] = "AA4";
        symbols[4] = "AA5";
        symbols[5] = "AA6";
        symbols[6] = "AA7";
        symbols[7] = "USD";
        symbols[8] = "AA8";
        vm.expectRevert("FAIL_USD_CANT_BE_SET");
        std3.listing(symbols);

        symbols = new string[](9);
        symbols[0] = "BB1";
        symbols[1] = "BB2";
        symbols[2] = "BB3";
        symbols[3] = "BB4";
        symbols[4] = "BB5";
        symbols[5] = "BB6";
        symbols[6] = "BB7";
        symbols[7] = "BB8";
        symbols[8] = "BB9";
        std3.listing(symbols);
        Slot memory s0 = decodeSlot(0);
        Slot memory s1 = decodeSlot(1);
        Slot memory s0Expected = Slot(
            0,
            6,
            TimeOffsetAndPrice(0, 0, "BB1"),
            TimeOffsetAndPrice(0, 0, "BB2"),
            TimeOffsetAndPrice(0, 0, "BB3"),
            TimeOffsetAndPrice(0, 0, "BB4"),
            TimeOffsetAndPrice(0, 0, "BB5"),
            TimeOffsetAndPrice(0, 0, "BB6")
        );
        Slot memory s1Expected = Slot(
            0,
            3,
            TimeOffsetAndPrice(0, 0, "BB7"),
            TimeOffsetAndPrice(0, 0, "BB8"),
            TimeOffsetAndPrice(0, 0, "BB9"),
            TimeOffsetAndPrice(0, 0, ""),
            TimeOffsetAndPrice(0, 0, ""),
            TimeOffsetAndPrice(0, 0, "")
        );

        assertEq(keccak256(abi.encode("0.", s0, "1.", s1)), keccak256(abi.encode("0.", s0Expected, "1.", s1Expected)));
    }

    function testListing_FAIL_SYMBOL_IS_ALREADY_SET() public {
        string[] memory symbols = new string[](9);
        symbols[0] = "AA1";
        symbols[1] = "AA2";
        symbols[2] = "AA3";
        symbols[3] = "AA4";
        symbols[4] = "AA5";
        symbols[5] = "AA6";
        symbols[6] = "AA7";
        symbols[7] = "AA8";
        symbols[8] = "AA9";
        std3.listing(symbols);

        for (uint256 i = 0; i < 9; i++) {
            string[] memory newSymbols = new string[](1);
            newSymbols[0] = symbols[i];
            vm.expectRevert("FAIL_SYMBOL_IS_ALREADY_SET");
            std3.listing(newSymbols);
        }

        for (uint256 i = 0; i < 9; i++) {
            string[] memory newSymbols = new string[](4);
            newSymbols[0] = "BB1";
            newSymbols[1] = "BB2";
            newSymbols[2] = "BB3";
            newSymbols[3] = "BB4";
            newSymbols[i % 4] = symbols[i];
            vm.expectRevert("FAIL_SYMBOL_IS_ALREADY_SET");
            std3.listing(newSymbols);
        }

        for (uint256 i = 0; i < 9; i++) {
            string[] memory newSymbols = new string[](6);
            newSymbols[0] = "BB1";
            newSymbols[1] = "BB2";
            newSymbols[2] = "BB3";
            newSymbols[3] = "BB4";
            newSymbols[4] = "BB5";
            newSymbols[5] = "BB6";
            newSymbols[i % 6] = symbols[i];
            vm.expectRevert("FAIL_SYMBOL_IS_ALREADY_SET");
            std3.listing(newSymbols);
        }

        for (uint256 i = 0; i < 9; i++) {
            string[] memory newSymbols = new string[](8);
            newSymbols[0] = "BB1";
            newSymbols[1] = "BB2";
            newSymbols[2] = "BB3";
            newSymbols[3] = "BB4";
            newSymbols[4] = "BB5";
            newSymbols[5] = "BB6";
            newSymbols[6] = "BB7";
            newSymbols[7] = "BB8";
            newSymbols[i % 8] = symbols[i];
            vm.expectRevert("FAIL_SYMBOL_IS_ALREADY_SET");
            std3.listing(newSymbols);
        }
    }

    function testDelisting_FAIL_SYMBOL_NOT_AVAILABLE() public {
        string[] memory symbols = new string[](9);
        symbols[0] = "AA1";
        symbols[1] = "AA2";
        symbols[2] = "AA3";
        symbols[3] = "AA4";
        symbols[4] = "AA5";
        symbols[5] = "AA6";
        symbols[6] = "AA7";
        symbols[7] = "AA8";
        symbols[8] = "AA9";
        std3.listing(symbols);

        for (uint256 i = 0; i < 9; i++) {
            string[] memory newSymbols = new string[](1);
            newSymbols[0] = "AA55";
            vm.expectRevert("FAIL_SYMBOL_NOT_AVAILABLE");
            std3.delisting(newSymbols);
        }

        for (uint256 i = 0; i < 9; i++) {
            string[] memory newSymbols = new string[](4);
            newSymbols[0] = symbols[i%4];
            newSymbols[1] = symbols[(i+1)%4];
            newSymbols[2] = symbols[(i+2)%4];
            newSymbols[3] = symbols[(i+3)%4];
            newSymbols[(i*i) % 4] = "AAA";
            vm.expectRevert("FAIL_SYMBOL_NOT_AVAILABLE");
            std3.delisting(newSymbols);
        }

        for (uint256 i = 0; i < 9; i++) {
            string[] memory newSymbols = new string[](6);
            newSymbols[0] = symbols[i%6];
            newSymbols[1] = symbols[(i+1)%6];
            newSymbols[2] = symbols[(i+2)%6];
            newSymbols[3] = symbols[(i+3)%6];
            newSymbols[4] = symbols[(i+4)%6];
            newSymbols[5] = symbols[(i+5)%6];
            newSymbols[(i*i) % 6] = "AAA";
            vm.expectRevert("FAIL_SYMBOL_NOT_AVAILABLE");
            std3.delisting(newSymbols);
        }

        for (uint256 i = 0; i < 9; i++) {
            string[] memory newSymbols = new string[](8);
            newSymbols[0] = symbols[i%8];
            newSymbols[1] = symbols[(i+1)%8];
            newSymbols[2] = symbols[(i+2)%8];
            newSymbols[3] = symbols[(i+3)%8];
            newSymbols[4] = symbols[(i+4)%8];
            newSymbols[5] = symbols[(i+5)%8];
            newSymbols[6] = symbols[(i+6)%8];
            newSymbols[7] = symbols[(i+7)%8];
            newSymbols[(i*i) % 8] = "AAA";
            vm.expectRevert("FAIL_SYMBOL_NOT_AVAILABLE");
            std3.delisting(newSymbols);
        }
    }

    function testRelay_FAIL_SYMBOL_NOT_AVAILABLE() public {
        string[] memory symbols = new string[](9);
        symbols[0] = "AA1";
        symbols[1] = "AA2";
        symbols[2] = "AA3";
        symbols[3] = "AA4";
        symbols[4] = "AA5";
        symbols[5] = "AA6";
        symbols[6] = "AA7";
        symbols[7] = "AA8";
        symbols[8] = "AA9";
        std3.listing(symbols);

        for (uint256 i = 0; i < 9; i++) {
            STD_E_3.Price[] memory ps = new STD_E_3.Price[](4);
            ps[0] = STD_E_3.Price(100, "AA1");
            ps[1] = STD_E_3.Price(200, "AA8");
            ps[2] = STD_E_3.Price(300, "AA9");
            ps[3] = STD_E_3.Price(400, "AA5");
            ps[i % 4] = STD_E_3.Price(1000, "BBB");
            vm.expectRevert("FAIL_SYMBOL_NOT_AVAILABLE");
            std3.relay(5555, MOCK_REQ_ID, ps);
        }
    }

    function testRelay_FAIL_NEW_TIME_LT_CURRENT_OR_EXCEED_3_DAYS() public {
        string[] memory symbols = new string[](9);
        symbols[0] = "AA1";
        symbols[1] = "AA2";
        symbols[2] = "AA3";
        symbols[3] = "AA4";
        symbols[4] = "AA5";
        symbols[5] = "AA6";
        symbols[6] = "AA7";
        symbols[7] = "AA8";
        symbols[8] = "AA9";
        std3.listing(symbols);

        STD_E_3.Price[] memory ps = new STD_E_3.Price[](9);
        ps[0] = STD_E_3.Price(700, "AA7");
        ps[1] = STD_E_3.Price(800, "AA8");
        ps[2] = STD_E_3.Price(900, "AA9");
        ps[3] = STD_E_3.Price(100, "AA1");
        ps[4] = STD_E_3.Price(200, "AA2");
        ps[5] = STD_E_3.Price(300, "AA3");
        ps[6] = STD_E_3.Price(400, "AA4");
        ps[7] = STD_E_3.Price(500, "AA5");
        ps[8] = STD_E_3.Price(600, "AA6");

        std3.relayRebase(1e6, MOCK_REQ_ID, ps);

        ps = new STD_E_3.Price[](4);
        ps[0] = STD_E_3.Price(110, "AA1");
        ps[1] = STD_E_3.Price(880, "AA8");
        ps[2] = STD_E_3.Price(990, "AA9");
        ps[3] = STD_E_3.Price(550, "AA5");
        std3.relay(1e6 + (1<<17), MOCK_REQ_ID, ps);

        Slot memory s0 = decodeSlot(0);
        Slot memory s1 = decodeSlot(1);
        Slot memory s0Expected = Slot(
            1e6,
            6,
            TimeOffsetAndPrice((1<<17), 110, "AA1"),
            TimeOffsetAndPrice(0, 200, "AA2"),
            TimeOffsetAndPrice(0, 300, "AA3"),
            TimeOffsetAndPrice(0, 400, "AA4"),
            TimeOffsetAndPrice((1<<17), 550, "AA5"),
            TimeOffsetAndPrice(0, 600, "AA6")
        );
        Slot memory s1Expected = Slot(
            1e6,
            3,
            TimeOffsetAndPrice(0, 700, "AA7"),
            TimeOffsetAndPrice((1<<17), 880, "AA8"),
            TimeOffsetAndPrice((1<<17), 990, "AA9"),
            TimeOffsetAndPrice(0, 0, ""),
            TimeOffsetAndPrice(0, 0, ""),
            TimeOffsetAndPrice(0, 0, "")
        );

        assertEq(keccak256(abi.encode("0.", s0, "1.", s1)), keccak256(abi.encode("0.", s0Expected, "1.", s1Expected)));

        ps = new STD_E_3.Price[](4);
        ps[0] = STD_E_3.Price(111, "AA1");
        ps[1] = STD_E_3.Price(888, "AA8");
        ps[2] = STD_E_3.Price(999, "AA9");
        ps[3] = STD_E_3.Price(555, "AA5");
        vm.expectRevert("FAIL_NEW_TIME_<=_CURRENT");
        std3.relay(1e6 + (1<<16), MOCK_REQ_ID, ps);
        vm.expectRevert("FAIL_NEW_TIME_<=_CURRENT");
        std3.relay(1e6 + (1<<17), MOCK_REQ_ID, ps);

        vm.expectRevert("FAIL_DELTA_TIME_EXCEED_3_DAYS");
        std3.relay(1e6 + (1<<18) + 1, MOCK_REQ_ID, ps);
    }

    function testRelayRebase_FAIL_SYMBOL_NOT_AVAILABLE() public {
        string[] memory symbols = new string[](9);
        symbols[0] = "AA1";
        symbols[1] = "AA2";
        symbols[2] = "AA3";
        symbols[3] = "AA4";
        symbols[4] = "AA5";
        symbols[5] = "AA6";
        symbols[6] = "AA7";
        symbols[7] = "AA8";
        symbols[8] = "AA9";
        std3.listing(symbols);

        for (uint256 i = 0; i < 6; i++) {
            STD_E_3.Price[] memory ps = new STD_E_3.Price[](6);
            ps[0] = STD_E_3.Price(100, "AA1");
            ps[1] = STD_E_3.Price(200, "AA2");
            ps[2] = STD_E_3.Price(300, "AA3");
            ps[3] = STD_E_3.Price(400, "AA4");
            ps[4] = STD_E_3.Price(500, "AA5");
            ps[5] = STD_E_3.Price(600, "AA6");
            ps[i] = STD_E_3.Price(1000, "BBB");
            vm.expectRevert("FAIL_SYMBOL_NOT_AVAILABLE");
            std3.relayRebase(5555, MOCK_REQ_ID, ps);
        }
    }

    function testRelayRebase_FAIL_IN_ORDER_CHEKCING_permHelper(uint256 n, STD_E_3.Price[] memory ps) private {
        if (n == 1) {
            Slot memory s = decodeSlot(0);
            if (
                ps[0].ticks < ps[1].ticks &&
                ps[1].ticks < ps[2].ticks &&
                ps[2].ticks < ps[3].ticks &&
                ps[3].ticks < ps[4].ticks &&
                ps[4].ticks < ps[5].ticks
            ) {
                std3.relayRebase(s.time + 1, MOCK_REQ_ID, ps);
            } else {
                if (ps[0].ticks == 1) {
                    vm.expectRevert("FAIL_INVALID_ID_SEQUENCE");
                    std3.relayRebase(s.time + 1, MOCK_REQ_ID, ps);
                } else {
                    vm.expectRevert("FAIL_INVALID_FIRST_ID");
                    std3.relayRebase(s.time + 1, MOCK_REQ_ID, ps);
                }
            }
        } else {
            for (uint i = 0; i < n - 1; i++) {
                testRelayRebase_FAIL_IN_ORDER_CHEKCING_permHelper(n - 1, ps);
                if (n & 1 != 0) {
                    (ps[0], ps[n - 1]) = (ps[n - 1], ps[0]);
                } else {
                    (ps[i], ps[n - 1]) = (ps[n - 1], ps[i]);
                }
            }
            testRelayRebase_FAIL_IN_ORDER_CHEKCING_permHelper(n - 1, ps);
        }
    }

    function testRelayRebase_FAIL_IN_ORDER_CHEKCING() public {
        string[] memory symbols = new string[](15);
        symbols[0] = "ETH";
        symbols[1] = "BNB";
        symbols[2] = "ADA";
        symbols[3] = "BTC";
        symbols[4] = "XRP";
        symbols[5] = "DOT";
        symbols[6] = "SOL";
        symbols[7] = "UNI";
        symbols[8] = "LINK";
        symbols[9] = "SNX";
        symbols[10] = "DAI";
        symbols[11] = "DOGE";
        symbols[12] = "BAND";
        symbols[13] = "ATOM";
        symbols[14] = "OSMO";
        std3.listing(symbols);

        STD_E_3.Price[] memory ps = new STD_E_3.Price[](6);
        ps[0] = STD_E_3.Price(1, "ETH");
        ps[1] = STD_E_3.Price(2, "BNB");
        ps[2] = STD_E_3.Price(3, "ADA");
        ps[3] = STD_E_3.Price(4, "BTC");
        ps[4] = STD_E_3.Price(5, "XRP");
        ps[5] = STD_E_3.Price(6, "DOT");
        std3.relayRebase(999, MOCK_REQ_ID, ps);
        for (uint256 i = 0; i < 6; i++) {
            (uint256 ticks, uint256 lastUpdated) = std3.getTicksAndTime(ps[i].symbol);
            assertEq(ticks, ps[i].ticks);
            assertEq(lastUpdated, 999);
        }

        testRelayRebase_FAIL_IN_ORDER_CHEKCING_permHelper(ps.length, ps);
        Slot memory s = decodeSlot(0);
        assertEq(s.time, 1000);

        ps = new STD_E_3.Price[](9);
        ps[0] = STD_E_3.Price(10, "ETH");
        ps[1] = STD_E_3.Price(20, "BNB");
        ps[2] = STD_E_3.Price(30, "ADA");
        ps[3] = STD_E_3.Price(40, "BTC");
        ps[4] = STD_E_3.Price(50, "XRP");
        ps[5] = STD_E_3.Price(60, "DOT");
        ps[6] = STD_E_3.Price(120, "BAND");
        ps[7] = STD_E_3.Price(130, "ATOM");
        ps[8] = STD_E_3.Price(140, "OSMO");
        std3.relayRebase(1001, MOCK_REQ_ID, ps);

        (ps[6],ps[7],ps[8]) = (STD_E_3.Price(120, "BAND"),STD_E_3.Price(130, "OSMO"),STD_E_3.Price(140, "ATOM"));
        vm.expectRevert("FAIL_INVALID_ID_SEQUENCE");
        std3.relayRebase(1002, MOCK_REQ_ID, ps);

        (ps[6],ps[7],ps[8]) = (STD_E_3.Price(120, "ATOM"),STD_E_3.Price(130, "BAND"),STD_E_3.Price(140, "OSMO"));
        vm.expectRevert("FAIL_INVALID_FIRST_ID");
        std3.relayRebase(1002, MOCK_REQ_ID, ps);

        (ps[6],ps[7],ps[8]) = (STD_E_3.Price(120, "OSMO"),STD_E_3.Price(130, "BAND"),STD_E_3.Price(140, "ATOM"));
        vm.expectRevert("FAIL_INVALID_FIRST_ID");
        std3.relayRebase(1002, MOCK_REQ_ID, ps);

        (ps[6],ps[7],ps[8]) = (STD_E_3.Price(120, "ATOM"),STD_E_3.Price(130, "ATOM"),STD_E_3.Price(140, "BAND"));
        vm.expectRevert("FAIL_INVALID_FIRST_ID");
        std3.relayRebase(1002, MOCK_REQ_ID, ps);

        (ps[6],ps[7],ps[8]) = (STD_E_3.Price(120, "OSMO"),STD_E_3.Price(130, "ATOM"),STD_E_3.Price(140, "BAND"));
        vm.expectRevert("FAIL_INVALID_FIRST_ID");
        std3.relayRebase(1002, MOCK_REQ_ID, ps);
    }

    function testRelayRebase_FAIL_NEW_TIME_LT_CURRENT_OR_EXCEED_3_DAYS() public {
        string[] memory symbols = new string[](9);
        symbols[0] = "AA1";
        symbols[1] = "AA2";
        symbols[2] = "AA3";
        symbols[3] = "AA4";
        symbols[4] = "AA5";
        symbols[5] = "AA6";
        symbols[6] = "AA7";
        symbols[7] = "AA8";
        symbols[8] = "AA9";
        std3.listing(symbols);

        STD_E_3.Price[] memory ps = new STD_E_3.Price[](9);
        ps[0] = STD_E_3.Price(700, "AA7");
        ps[1] = STD_E_3.Price(800, "AA8");
        ps[2] = STD_E_3.Price(900, "AA9");
        ps[3] = STD_E_3.Price(100, "AA1");
        ps[4] = STD_E_3.Price(200, "AA2");
        ps[5] = STD_E_3.Price(300, "AA3");
        ps[6] = STD_E_3.Price(400, "AA4");
        ps[7] = STD_E_3.Price(500, "AA5");
        ps[8] = STD_E_3.Price(600, "AA6");

        std3.relayRebase(1e6, MOCK_REQ_ID, ps);

        vm.expectRevert("FAIL_NEW_TIME_<=_CURRENT");
        std3.relay(1e6 - 1, MOCK_REQ_ID, ps);
        vm.expectRevert("FAIL_NEW_TIME_<=_CURRENT");
        std3.relay(1e6, MOCK_REQ_ID, ps);

        vm.expectRevert("FAIL_DELTA_TIME_EXCEED_3_DAYS");
        std3.relay(1e6 + (1<<18) + 1, MOCK_REQ_ID, ps);

        std3.relayRebase(1e6 + 1, MOCK_REQ_ID, ps);

        Slot memory s0 = decodeSlot(0);
        Slot memory s1 = decodeSlot(1);
        Slot memory s0Expected = Slot(
            1e6 + 1,
            6,
            TimeOffsetAndPrice(0, 100, "AA1"),
            TimeOffsetAndPrice(0, 200, "AA2"),
            TimeOffsetAndPrice(0, 300, "AA3"),
            TimeOffsetAndPrice(0, 400, "AA4"),
            TimeOffsetAndPrice(0, 500, "AA5"),
            TimeOffsetAndPrice(0, 600, "AA6")
        );
        Slot memory s1Expected = Slot(
            1e6 + 1,
            3,
            TimeOffsetAndPrice(0, 700, "AA7"),
            TimeOffsetAndPrice(0, 800, "AA8"),
            TimeOffsetAndPrice(0, 900, "AA9"),
            TimeOffsetAndPrice(0, 0, ""),
            TimeOffsetAndPrice(0, 0, ""),
            TimeOffsetAndPrice(0, 0, "")
        );

        assertEq(keccak256(abi.encode("0.", s0, "1.", s1)), keccak256(abi.encode("0.", s0Expected, "1.", s1Expected)));
    }

    function testRelayRebase_FAIL_INCONSISTENT_SIZES() public {
        string[] memory symbols = new string[](9);
        symbols[0] = "AA1";
        symbols[1] = "AA2";
        symbols[2] = "AA3";
        symbols[3] = "AA4";
        symbols[4] = "AA5";
        symbols[5] = "AA6";
        symbols[6] = "AA7";
        symbols[7] = "AA8";
        symbols[8] = "AA9";
        std3.listing(symbols);

        STD_E_3.Price[] memory ps = new STD_E_3.Price[](9);
        ps[0] = STD_E_3.Price(700, "AA7");
        ps[1] = STD_E_3.Price(800, "AA8");
        ps[2] = STD_E_3.Price(900, "AA9");
        ps[3] = STD_E_3.Price(100, "AA1");
        ps[4] = STD_E_3.Price(200, "AA2");
        ps[5] = STD_E_3.Price(300, "AA3");
        ps[6] = STD_E_3.Price(400, "AA4");
        ps[7] = STD_E_3.Price(500, "AA5");
        ps[8] = STD_E_3.Price(600, "AA6");
        std3.relayRebase(1e6, MOCK_REQ_ID, ps);

        ps = new STD_E_3.Price[](8);
        ps[0] = STD_E_3.Price(700, "AA7");
        ps[1] = STD_E_3.Price(800, "AA8");
        ps[2] = STD_E_3.Price(900, "AA9");
        ps[3] = STD_E_3.Price(100, "AA1");
        ps[4] = STD_E_3.Price(200, "AA2");
        ps[5] = STD_E_3.Price(300, "AA3");
        ps[6] = STD_E_3.Price(400, "AA4");
        ps[7] = STD_E_3.Price(500, "AA5");
        vm.expectRevert("FAIL_INCONSISTENT_SIZES");
        std3.relayRebase(1e6 + 1, MOCK_REQ_ID, ps);

        ps = new STD_E_3.Price[](8);
        ps[0] = STD_E_3.Price(100, "AA1");
        ps[1] = STD_E_3.Price(200, "AA2");
        ps[2] = STD_E_3.Price(300, "AA3");
        ps[3] = STD_E_3.Price(400, "AA4");
        ps[4] = STD_E_3.Price(500, "AA5");
        ps[5] = STD_E_3.Price(600, "AA6");
        ps[6] = STD_E_3.Price(700, "AA7");
        ps[7] = STD_E_3.Price(800, "AA8");
        vm.expectRevert("FAIL_INCONSISTENT_SIZES");
        std3.relayRebase(1e6 + 1, MOCK_REQ_ID, ps);
    }

    function testGetReferenceData() public {
        string[] memory symbols = new string[](4);
        symbols[0] = "BTC";
        symbols[1] = "ETH";
        symbols[2] = "DAI";
        symbols[3] = "USDC";
        std3.listing(symbols);

        STD_E_3.Price[] memory ps = new STD_E_3.Price[](4);
        ps[0] = STD_E_3.Price(1111, "BTC");
        ps[1] = STD_E_3.Price(2222, "ETH");
        ps[2] = STD_E_3.Price(3333, "DAI");
        ps[3] = STD_E_3.Price(4444, "USDC");
        std3.relayRebase(1e6, MOCK_REQ_ID, ps);

        ps = new STD_E_3.Price[](1);
        ps[0] = STD_E_3.Price(364087, "BTC");
        std3.relay(1e6 + 1, MOCK_REQ_ID, ps);

        ps[0] = STD_E_3.Price(337088, "ETH");
        std3.relay(1e6 + 2, MOCK_REQ_ID, ps);

        ps[0] = STD_E_3.Price(262138, "DAI");
        std3.relay(1e6 + 3, MOCK_REQ_ID, ps);

        ps[0] = STD_E_3.Price(262140, "USDC");
        std3.relay(1e6 + 4, MOCK_REQ_ID, ps);

        assertEq(
            abi.encode(std3.getReferenceData("USD", "USD")),
            abi.encode(IStdReference.ReferenceData(1e18, block.timestamp, block.timestamp)
        ));
        assertEq(
            abi.encode(std3.getReferenceData("BTC", "USD")),
            abi.encode(IStdReference.ReferenceData(26736643493622462548344, 1e6 + 1, block.timestamp)
        ));
        assertEq(
            abi.encode(std3.getReferenceData("ETH", "USD")),
            abi.encode(IStdReference.ReferenceData(1797272119099405449069, 1e6 + 2, block.timestamp)
        ));
        assertEq(
            abi.encode(std3.getReferenceData("DAI", "USD")),
            abi.encode(IStdReference.ReferenceData(999400209944012597, 1e6 + 3, block.timestamp)
        ));
        assertEq(
            abi.encode(std3.getReferenceData("USDC", "USD")),
            abi.encode(IStdReference.ReferenceData(999600099980003499, 1e6 + 4, block.timestamp)
        ));
        assertEq(
            abi.encode(std3.getReferenceData("BTC", "ETH")),
            abi.encode(IStdReference.ReferenceData(14876235607004196601, 1e6 + 1, 1e6 + 2)
        ));
        assertEq(
            abi.encode(std3.getReferenceData("ETH", "BTC")),
            abi.encode(IStdReference.ReferenceData(67221306950070671, 1e6 + 2, 1e6 + 1)
        ));
        assertEq(
            abi.encode(std3.getReferenceData("DAI", "USDC")),
            abi.encode(IStdReference.ReferenceData(999800029996000499, 1e6 + 3, 1e6 + 4)
        ));
        assertEq(
            abi.encode(std3.getReferenceData("USDC", "DAI")),
            abi.encode(IStdReference.ReferenceData(1000200009999999999, 1e6 + 4, 1e6 + 3)
        ));
    }
}
