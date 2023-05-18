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

    function _max(uint256 a, uint256 b) private pure returns(uint256 c) { c = a > b ? a: b; }
    function _maxTimeOffset(uint256 sVal) private pure returns(uint256 c) {
        unchecked {
            c = _max(
                (sVal >> 19) & ((1<<18) - 1),
                _max(
                    (sVal >> 56) & ((1<<18) - 1),
                    _max(
                        (sVal >> 93) & ((1<<18) - 1),
                        _max(
                            (sVal >> 130) & ((1<<18) - 1),
                            _max(
                                (sVal >> 167) & ((1<<18) - 1),
                                (sVal >> 204) & ((1<<18) - 1)
                            )
                        )
                    )
                )
            );
        }
    }

    function maxTimeOffset(uint256 slotID) public view returns(uint256 v) {
        v = _maxTimeOffset(refs[slotID]);
    }
    
    function _getTicksAndTime(string memory symbol) private view returns (uint256 ticks, uint256 lastUpdated) {
        unchecked {
            uint256 id = symbolsToIDs[symbol];
            require(id != 0, "FAIL_SYMBOL_NOT_AVAILABLE");
            uint256 sVal = refs[(id - 1) / 6];
            uint256 index = (id - 1) % 6;
            uint256 shiftLen = 185 - (index * 37);
            ticks = (sVal >> shiftLen) & ((1 << 19) - 1);
            shiftLen += 19;
            lastUpdated = ((sVal >> 225) & ((1 << 31) - 1)) + ((sVal >> shiftLen) & ((1 << 18) - 1));
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
        uint256 sSize = (sVal >> 222) & ((1<<3) - 1);

        _totalSymbolsCount++;
        symbolsToIDs[symbols[0]] = _totalSymbolsCount;
        idsToSymbols[_totalSymbolsCount] = symbols[0];

        sSize++;
        sVal = (sVal & (type(uint256).max - ((((1<<3) - 1)) << 222))) | (sSize << 222);

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
                sSize = (sVal >> 222) & ((1<<3) - 1);
            }

            sSize++;
            sVal = (sVal & (type(uint256).max - ((((1<<3) - 1)) << 222))) | (sSize << 222);
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
            uint256 sSize = (sVal >> 222) & ((1<<3) - 1);
            uint256 shiftLen = 37*(5-indexInSlot);
            uint256 lastTAP = (sVal >> shiftLen) & ((1 << 37) - 1);
            sSize--;
            sVal &= type(uint256).max - (((((1<<3) - 1)) << 222) | ((1 << (37*(6 - sSize))) - 1));
            refs[slotID] = (sVal & (type(uint256).max - ((((1<<3) - 1)) << 222))) | (sSize << 222);

            slotID = (id - 1) / 6;
            indexInSlot = (id - 1) % 6;
            shiftLen = 37*(5-indexInSlot);
            refs[slotID] = (refs[slotID] & (type(uint256).max - (((1<<37) - 1) << shiftLen))) | (lastTAP << shiftLen);

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
            uint256 sTime;
            uint256 sVal;
            for (uint256 i = 0; i < ps.length; i++) {
                id = symbolsToIDs[ps[i].symbol];
                require(id != 0, "FAIL_SYMBOL_NOT_AVAILABLE");

                uint256 slotID = (id - 1) / 6;
                if (sid != slotID) {
                    if (sVal != 0) {
                        refs[sid] = sVal;
                    }

                    sVal = refs[slotID];
                    sid = slotID;
                    sTime = (sVal >> 225) & ((1 << 31) - 1);
                }

                uint256 indexInSlot = (id - 1) % 6;
                uint256 shiftLen = 204 - (37*indexInSlot);
                require(sTime + ((sVal >> shiftLen) & ((1 << 18) - 1)) < time, "FAIL_NEW_TIME_<=_CURRENT");
                require(time < sTime + (1<<18), "FAIL_DELTA_TIME_EXCEED_3_DAYS");
                uint256 delta = time - sTime;

                shiftLen = shiftLen - 19;
                sVal &= ~(uint256((1 << 37) - 1) << shiftLen);
                sVal |= ((delta << 19) | ps[i].ticks & ((1<<19) - 1)) << shiftLen;
            }

            if (sVal != 0) {
                refs[sid] = sVal;
            }
        }
    }

    function relayRebase(uint256 time, uint256 requestID, Price[] calldata ps) external onlyRole(RELAYER_ROLE) {
        unchecked {
            uint256 id;
            uint256 sid;
            uint256 sVal;
            uint256 sTime;
            uint256 sSize;
            uint256 expectedSumOfSizes;
            for (uint i = 0; i < ps.length; i++) {
                uint256 nextID = symbolsToIDs[ps[i].symbol];
                require(nextID != 0, "FAIL_SYMBOL_NOT_AVAILABLE");

                if (sSize != 0) {
                    require((id - 1) / 6 == sid && id + 1 == nextID, "FAIL_INVALID_ID_SEQUENCE");

                    id = nextID;
                    uint256 shiftLen = 185 - 37 * ((id - 1) % 6);
                    sVal |= (ps[i].ticks & ((1<<19) - 1)) << shiftLen;
                } else {
                    require((nextID - 1) % 6 == 0, "FAIL_INVALID_FIRST_ID");
                    if (sVal != 0) refs[sid] = sVal;

                    id = nextID;
                    sid = (id - 1) / 6;
                    sVal = refs[sid];
                    sTime = (sVal >> 225) & ((1<<31) - 1);
                    require(_maxTimeOffset(sVal) + sTime < time, "FAIL_NEW_TIME_<=_MAX_CURRENT");
                    sSize = (sVal >> 222) & ((1<<3) - 1);
                    sVal = (sVal & (((1<<3) - 1) << 222)) | ((time & ((1<<31) - 1)) << 225) | (ps[i].ticks << 185);

                    expectedSumOfSizes += sSize;
                }

                sSize--;
            }

            require(expectedSumOfSizes == ps.length, "FAIL_INCONSISTENT_SIZES");
            if (sVal != 0) refs[sid] = sVal;
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
