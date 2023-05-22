// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

interface IStdReference {
    /// A structure returned whenever someone requests for standard reference data.
    struct ReferenceData {
        uint256 rate; // base/quote exchange rate, multiplied by 1e18.
        uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
        uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }

    /// Returns the price data for the given base/quote pair. Revert if not available.
    function getReferenceData(string memory _base, string memory _quote) external view returns (ReferenceData memory);

    /// Similar to getReferenceData, but with multiple base/quote pairs at once.
    function getReferenceDataBulk(string[] memory _bases, string[] memory _quotes) external view returns (ReferenceData[] memory);
}

abstract contract StdReferenceBase is IStdReference {
    function getReferenceData(string memory _base, string memory _quote) public view virtual override returns (ReferenceData memory);

    function getReferenceDataBulk(string[] memory _bases, string[] memory _quotes) public view override returns (ReferenceData[] memory) {
        require(_bases.length == _quotes.length, "BAD_INPUT_LENGTH");
        uint256 len = _bases.length;
        ReferenceData[] memory results = new ReferenceData[](len);
        for (uint256 idx = 0; idx < len; idx++) {
            results[idx] = getReferenceData(_bases[idx], _quotes[idx]);
        }
        return results;
    }
}

contract STD_E_3 is AccessControl, StdReferenceBase, Initializable {

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 private constant USD = keccak256(bytes("USD"));

    struct Price {
        uint256 ticks;
        string symbol;
    }

    uint256 public totalSymbolsCount = 0;

    // storage
    // 31|3|(19+18)*6|
    mapping(uint256 => uint256) public refs;
    mapping(string => uint256) public symbolsToIDs;
    mapping(uint256 => string) public idsToSymbols;

    function initialize() public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(RELAYER_ROLE, msg.sender);
    }

    function _extractSlotTime(uint256 val) private pure returns (uint256 t) {
        t = (val >> 225) & ((1 << 31) - 1);
    }

    function _extractSize(uint256 val) private pure returns (uint256 s) {
        s = (val >> 222) & ((1<<3) - 1);
    }

    function _extractTicks(uint256 val, uint256 shiftLen) private pure returns (uint256 ticks) {
        ticks = (val >> shiftLen) & ((1 << 19) - 1);
    }

    function _extractTimeOffset(uint256 val, uint256 shiftLen) private pure returns (uint256 offset) {
        offset = (val >> shiftLen) & ((1 << 18) - 1);
    }

    function _setTime(uint256 val, uint256 time) private pure returns (uint256 newVal) {
        newVal = (val & (type(uint256).max >> 31)) | (time << 225);
    }

    function _setSize(uint256 val, uint256 size) private pure returns (uint256 newVal) {
        newVal = (val & (type(uint256).max - ((((1<<3) - 1)) << 222))) | (size << 222);
    }

    function _setTimeOffset(uint256 val, uint256 timeOffset, uint256 shiftLen) private pure returns (uint256 newVal) {
        newVal = (val & ~(uint256((1 << 18) - 1) << (shiftLen + 19))) | (timeOffset << (shiftLen + 19));
    }

    function _setTicksAndTimeOffset(uint256 val, uint256 offset, uint256 ticks, uint256 shiftLen) private pure returns(uint256 newVal) {
        newVal = val & (~(uint256((1 << 37) - 1) << shiftLen));
        newVal |= ((offset << 19) | ticks & ((1<<19) - 1)) << shiftLen;
    }
    
    function _getTicksAndTime(string memory symbol) private view returns (uint256 ticks, uint256 lastUpdated) {
        unchecked {
            uint256 id = symbolsToIDs[symbol];
            require(id != 0, "FAIL_SYMBOL_NOT_AVAILABLE");
            uint256 sVal = refs[(id - 1) / 6];
            uint256 index = (id - 1) % 6;
            uint256 shiftLen = 185 - (index * 37);
            (ticks, lastUpdated) = (_extractTicks(sVal, shiftLen), _extractTimeOffset(sVal, shiftLen + 19));
            lastUpdated += _extractSlotTime(sVal);
        }
    }

    function getTicksAndTime(string memory symbol) public view returns(uint256 ticks, uint256 lastUpdated) {
        (ticks, lastUpdated) = _getTicksAndTime(symbol);
    }

    function _getPriceFromTick(uint256 x) private pure returns(uint256 y) {
        unchecked {
            require(x != 0, "FAIL_TICKS_0_IS_AN_EMPTY_PRICE");
            y = 649037107316853453566312041152512;
            if (x < 262144) {
                x = 262144 - x;
                if (x & 0x01 != 0) y = (y * 649102011027585138911668672356627) >> 109;
                if (x & 0x02 != 0) y = (y * 649166921228687897425559839223862) >> 109;
                if (x & 0x04 != 0) y = (y * 649296761104602847291923925447306) >> 109;
                if (x & 0x08 != 0) y = (y * 649556518769447606681106054382372) >> 109;
                if (x & 0x10 != 0) y = (y * 650076345896668132522271100656030) >> 109;
                if (x & 0x20 != 0) y = (y * 651117248505878973533694452870408) >> 109;
                if (x & 0x40 != 0) y = (y * 653204056474534657407624669811404) >> 109;
                if (x & 0x80 != 0) y = (y * 657397758286396885483233885325217) >> 109;
                if (x & 0x0100 != 0) y = (y * 665866108005128170549362417755489) >> 109;
                if (x & 0x0200 != 0) y = (y * 683131470899774684431604377857106) >> 109;
                if (x & 0x0400 != 0) y = (y * 719016834742958293196733842540130) >> 109;
                if (x & 0x0800 != 0) y = (y * 796541835305874991615834691778664) >> 109;
                if (x & 0x1000 != 0) y = (y * 977569522974447437629335387266319) >> 109;
                if (x & 0x2000 != 0) y = (y * 1472399900522103311842374358851872) >> 109;
                if (x & 0x4000 != 0) y = (y * 3340273526146976564083509455290620) >> 109;
                if (x & 0x8000 != 0) y = (y * 17190738562859105750521122099339319) >> 109;
                if (x & 0x010000 != 0) y = (y * 455322953040804340936374685561109626) >> 109;
                if (x & 0x020000 != 0) y = (y * 319425483117388922324853186559947171877) >> 109;
                y = 649037107316853453566312041152512000000000000000000 / y;
            } else {
                x = x - 262144;
                if (x & 0x01 != 0) y = (y * 649102011027585138911668672356627) >> 109;
                if (x & 0x02 != 0) y = (y * 649166921228687897425559839223862) >> 109;
                if (x & 0x04 != 0) y = (y * 649296761104602847291923925447306) >> 109;
                if (x & 0x08 != 0) y = (y * 649556518769447606681106054382372) >> 109;
                if (x & 0x10 != 0) y = (y * 650076345896668132522271100656030) >> 109;
                if (x & 0x20 != 0) y = (y * 651117248505878973533694452870408) >> 109;
                if (x & 0x40 != 0) y = (y * 653204056474534657407624669811404) >> 109;
                if (x & 0x80 != 0) y = (y * 657397758286396885483233885325217) >> 109;
                if (x & 0x0100 != 0) y = (y * 665866108005128170549362417755489) >> 109;
                if (x & 0x0200 != 0) y = (y * 683131470899774684431604377857106) >> 109;
                if (x & 0x0400 != 0) y = (y * 719016834742958293196733842540130) >> 109;
                if (x & 0x0800 != 0) y = (y * 796541835305874991615834691778664) >> 109;
                if (x & 0x1000 != 0) y = (y * 977569522974447437629335387266319) >> 109;
                if (x & 0x2000 != 0) y = (y * 1472399900522103311842374358851872) >> 109;
                if (x & 0x4000 != 0) y = (y * 3340273526146976564083509455290620) >> 109;
                if (x & 0x8000 != 0) y = (y * 17190738562859105750521122099339319) >> 109;
                if (x & 0x010000 != 0) y = (y * 455322953040804340936374685561109626) >> 109;
                if (x & 0x020000 != 0) y = (y * 319425483117388922324853186559947171877) >> 109;
                y = (y * 1e18) / 649037107316853453566312041152512;
            }
        }
    }

    function getPriceFromTick(uint256 x) public pure returns(uint256 y) {
        y = _getPriceFromTick(x);
    }

    /**
     * @dev Grants `RELAYER_ROLE` to `accounts`.
     *
     * If each `account` had not been already granted `RELAYER_ROLE`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``RELAYER_ROLE``'s admin role.
     */
    function grantRelayers(address[] calldata accounts) external onlyRole(getRoleAdmin(RELAYER_ROLE)) {
        for (uint256 idx = 0; idx < accounts.length; idx++) {
            _grantRole(RELAYER_ROLE, accounts[idx]);
        }
    }

    /**
     * @dev Revokes `RELAYER_ROLE` from `accounts`.
     *
     * If each `account` had already granted `RELAYER_ROLE`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``RELAYER_ROLE``'s admin role.
     */
    function revokeRelayers(address[] calldata accounts) external onlyRole(getRoleAdmin(RELAYER_ROLE)) {
        for (uint256 idx = 0; idx < accounts.length; idx++) {
            _revokeRole(RELAYER_ROLE, accounts[idx]);
        }
    }

    function listing(string[] calldata symbols) public onlyRole(getRoleAdmin(RELAYER_ROLE)) {
        require(symbols.length != 0, "FAIL_SYMBOLS_IS_EMPTY");

        require(keccak256(bytes(symbols[0])) != USD, "FAIL_USD_CANT_BE_SET");
        require(symbolsToIDs[symbols[0]] == 0, "FAIL_SYMBOL_IS_ALREADY_SET");

        uint256 _totalSymbolsCount = totalSymbolsCount;
        uint256 sid = _totalSymbolsCount / 6;
        uint256 sVal = refs[sid];
        uint256 sSize = _extractSize(sVal);

        _totalSymbolsCount++;
        symbolsToIDs[symbols[0]] = _totalSymbolsCount;
        idsToSymbols[_totalSymbolsCount] = symbols[0];

        sSize++;
        sVal = _setSize(sVal, sSize);

        for (uint256 i = 1; i < symbols.length; i++) {
            require(keccak256(bytes(symbols[i])) != USD, "FAIL_USD_CANT_BE_SET");
            require(symbolsToIDs[symbols[i]] == 0, "FAIL_SYMBOL_IS_ALREADY_SET");

            uint256 slotID = _totalSymbolsCount / 6;

            _totalSymbolsCount++;
            symbolsToIDs[symbols[i]] = _totalSymbolsCount;
            idsToSymbols[_totalSymbolsCount] = symbols[i];

            if (sid != slotID) {
                refs[sid] = sVal;

                sid = slotID;
                sVal = refs[sid];
                sSize = _extractSize(sVal);
            }

            sSize++;
            sVal = _setSize(sVal, sSize);
        }

        refs[sid] = sVal;
        totalSymbolsCount = _totalSymbolsCount;
    }

    function delisting(string[] calldata symbols) public onlyRole(getRoleAdmin(RELAYER_ROLE)) {
        uint256 _totalSymbolsCount = totalSymbolsCount;
        for (uint256 i = 0; i < symbols.length; i++) {
            uint256 id = symbolsToIDs[symbols[i]];
            require(id != 0, "FAIL_SYMBOL_NOT_AVAILABLE");

            string memory lastSymbol = idsToSymbols[_totalSymbolsCount];

            symbolsToIDs[lastSymbol] = id;
            idsToSymbols[id] = lastSymbol;

            uint256 slotID = (_totalSymbolsCount - 1) / 6;
            uint256 indexInSlot = (_totalSymbolsCount - 1) % 6;
            uint256 sVal = refs[slotID];
            uint256 sSize = _extractSize(sVal);
            uint256 shiftLen = 37*(5-indexInSlot);
            uint256 lastSegment = (sVal >> shiftLen) & ((1 << 37) - 1);
            sSize--;
            sVal &= type(uint256).max << (37*(6 - sSize));
            refs[slotID] = _setSize(sVal, sSize);

            slotID = (id - 1) / 6;
            indexInSlot = (id - 1) % 6;
            shiftLen = 37*(5-indexInSlot);
            refs[slotID] = (refs[slotID] & (type(uint256).max - (((1<<37) - 1) << shiftLen))) | (lastSegment << shiftLen);

            delete symbolsToIDs[symbols[i]];
            delete idsToSymbols[_totalSymbolsCount];

            _totalSymbolsCount--;
        }

        totalSymbolsCount = _totalSymbolsCount;
    }

    function relay(uint256 time, uint256 requestID, Price[] calldata ps) external onlyRole(RELAYER_ROLE) {
        unchecked {
            uint256 id;
            uint256 sid = type(uint256).max;
            uint256 nextSID;
            uint256 sTime;
            uint256 sVal;
            uint256 shiftLen;
            for (uint256 i = 0; i < ps.length; i++) {
                id = symbolsToIDs[ps[i].symbol];
                require(id != 0, "FAIL_SYMBOL_NOT_AVAILABLE");

                nextSID = (id - 1) / 6;
                if (sid != nextSID) {
                    if (sVal != 0) refs[sid] = sVal;

                    sVal = refs[nextSID];
                    sid = nextSID;
                    sTime = _extractSlotTime(sVal);
                }

                shiftLen = 204 - (37*((id - 1) % 6));
                require(sTime + _extractTimeOffset(sVal, shiftLen) < time, "FAIL_NEW_TIME_<=_CURRENT");
                require(time < sTime + (1<<18), "FAIL_DELTA_TIME_EXCEED_3_DAYS");
                sVal = _setTicksAndTimeOffset(sVal, time - sTime, ps[i].ticks, shiftLen - 19);
            }

            if (sVal != 0) refs[sid] = sVal;
        }
    }

    function relayRebase(uint256 time, uint256 requestID, Price[] calldata ps) external onlyRole(RELAYER_ROLE) {
        unchecked {
            uint256 id;
            uint256 nextID;
            uint256 sVal;
            uint256 sTime;
            uint256 sSize;
            uint256 shiftLen;
            uint256 timeOffset;
            uint256 i;
            while (i < ps.length) {
                id = symbolsToIDs[ps[i].symbol];
                require(id != 0, "FAIL_SYMBOL_NOT_AVAILABLE");
                require((id - 1) % 6 == 0, "FAIL_INVALID_FIRST_ID");
                sVal = refs[(id - 1) / 6];
                (sTime, sSize) = (_extractSlotTime(sVal), _extractSize(sVal));
                require(sTime < time, "FAIL_NEW_TIME_<=_CURRENT");
                shiftLen = 204;
                timeOffset = _extractTimeOffset(sVal, shiftLen);
                shiftLen = shiftLen - 19;
                sVal = sTime + timeOffset <= time ?
                    _setTicksAndTimeOffset(sVal, 0, ps[i].ticks, shiftLen) :
                    _setTimeOffset(sVal, (sTime + timeOffset) - time, shiftLen);
                for (uint256 j = i + 1; j < i + sSize; j++) {
                    require(j < ps.length, "FAIL_INCONSISTENT_SIZES");
                    nextID = symbolsToIDs[ps[j].symbol];
                    require(nextID != 0, "FAIL_SYMBOL_NOT_AVAILABLE");
                    require(nextID + i == id + j, "FAIL_INVALID_ID_SEQUENCE");
                    shiftLen -= 18;
                    timeOffset = _extractTimeOffset(sVal, shiftLen);
                    shiftLen -= 19;
                    sVal = sTime + timeOffset <= time ?
                        _setTicksAndTimeOffset(sVal, 0, ps[j].ticks, shiftLen) :
                        _setTimeOffset(sVal, (sTime + timeOffset) - time, shiftLen);
                }
                refs[(id - 1) / 6] = _setTime(sVal, time);
                i += sSize;
            }
        }
    }

    function getReferenceData(string memory _base, string memory _quote) public override view returns (ReferenceData memory) {
        if (keccak256(bytes(_base)) == USD) {
            if (keccak256(bytes(_quote)) == USD) {
                return ReferenceData({rate: 1e18, lastUpdatedBase: block.timestamp, lastUpdatedQuote: block.timestamp});
            }
            (uint256 rate, uint256 lastUpdatedQuote) = _getTicksAndTime(_quote);
            return ReferenceData({rate: rate, lastUpdatedBase: block.timestamp, lastUpdatedQuote: lastUpdatedQuote});
        }
        (uint256 ticksBase, uint256 timeBase) = _getTicksAndTime(_base);
        if (keccak256(bytes(_quote)) == USD) {
            return ReferenceData({rate: _getPriceFromTick(ticksBase), lastUpdatedBase: timeBase, lastUpdatedQuote: block.timestamp});
        }
        (uint256 ticksQuote, uint256 timeQuote) = _getTicksAndTime(_quote);
        return ReferenceData({
            rate: _getPriceFromTick((ticksBase + 262144) - ticksQuote),
            lastUpdatedBase: timeBase,
            lastUpdatedQuote: timeQuote
        });
    }

}
