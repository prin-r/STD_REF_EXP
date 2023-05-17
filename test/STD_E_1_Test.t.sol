// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/STD_E_1.sol";

contract STD_E_1_Test is Test {
    STD_E_1 public std1;

    function setUp() public {
        std1 = new STD_E_1();
    }

    function decodeStorage(uint256 x) private {
        console.log("=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
        console.log("time:  ", (x & (2**30 - 1) << 226) >> 226);
        console.log("nonce: ", (x & (2**4 - 1) << 222) >> 222);
        console.log("mask: ", (x & (2**6 - 1) << 216) >> 216);
        uint256 offset = 199;
        for (uint256 i = 0; i < 6; i++) {
            console.log(i+1,". (time_frac, price) :", (x & (2**17 - 1) << (offset - (36*i)) ) >> (offset - (36*i)) , (x & (2**19 - 1) << (offset - 19 - (36*i))) >> (offset - 19 - (36*i)));
        }
        console.log("=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
    }

    function testRelay0_1() public {
        uint256 g = gasleft();
        (bool success, bytes memory returnData) = address(std1).call(hex"000000008000000404bffffff06d603a980411a808ae056ce047ec0b170223d1a8622c638115c01a2500534008ac00de00");
        console.log("gasUsed 1 >>>> ", g - gasleft());

        require(success, "Fail 0_1");

        // decodeStorage(std1.refs(1));
        // decodeStorage(std1.refs(2));
        // decodeStorage(std1.refs(3));
    }

    function testRelay0_2() public {
        uint256 g = gasleft();
        (bool success, bytes memory returnData) = address(std1).call(hex"00000000047a11fc04bf8000100028004b20f58010cc012fa047fc06828115c02b66068280f3080457034fe001c000a08007b002b200a98b1c18");
        console.log("gasUsed 2 >>>> ", g - gasleft());

        require(success, "Fail 0_2");

        // decodeStorage(std1.refs(1));
        // decodeStorage(std1.refs(2));
        // decodeStorage(std1.refs(3));

        (uint256 rate, uint256 lastUpdate) = std1._getRefData(11);
        console.log("rate = ", rate);
        console.log("lastUpdate = ", lastUpdate);
    }

    function testRelay1_1() public {
        uint256 g = gasleft();
        (bool success, bytes memory returnData) = address(std1).call(hex"000000010119ed4317ce27111cc03e87d00309612064ab039a19021c232255fe4b00");
        console.log("gasUsed 3 >>>> ", g - gasleft());

        require(success, "Fail 1_1");

        // decodeStorage(std1.refs(1));
        // decodeStorage(std1.refs(2));
        // decodeStorage(std1.refs(3));
    }
}
