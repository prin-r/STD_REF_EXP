// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/STD_E_2.sol";

contract STD_E_2_Test is Test {
    STD_E_2 public std2;

    function setUp() public {
        std2 = new STD_E_2();
        std2.setAllSymbols(26);
    }

    function decodeStorage(uint256 x) private {
        STD_E_2.Slot memory s = std2.decodeSlot(x);
        console.log("=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
        console.log("time:  ", s.time);
        console.log("nonce: ", s.nonce);
        console.log("count: ", s.count);
        console.log("price1: ", s.p1);
        console.log("price2: ", s.p2);
        console.log("price3: ", s.p3);
        console.log("price4: ", s.p4);
        console.log("price5: ", s.p5);
        console.log("price6: ", s.p6);
        console.log("price7: ", s.p7);
        console.log("price8: ", s.p8);
        console.log("price9: ", s.p9);
        console.log("price10: ", s.p10);
        console.log("price11: ", s.p11);
        console.log("=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
    }

    function testGet() public {
        // decodeStorage(0);
        // decodeStorage(1);
        // decodeStorage(2);
    }


    function testRelay0_1() public {
        uint256 g = gasleft();
        (bool success, bytes memory returnData) = address(std2).call(hex"00000000010012d687014045bc04f981bfe03a62071b808c480bab0111802e80053b022d002000d5fff0285b39c46f408de20e8a20");
        console.log("gasUsed 1 >>>> ", g - gasleft());

        require(success, "Fail 0_1");

        // decodeStorage(0);
        // decodeStorage(1);
        // decodeStorage(2);

        (uint256 rate, uint256 lastUpdate) = std2._getRefData(11);
        console.log("std2 rate = ", rate);
        console.log("std2 lastUpdate = ", lastUpdate);
    }

}
