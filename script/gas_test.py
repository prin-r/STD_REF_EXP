from web3 import Web3
import eth_abi
import math
import time
import json

mappping = {
    'bsc': {
    }
}

network = 'bsc'

# Connect to the Ethereum network
w3 = Web3(Web3.HTTPProvider(mappping[network]['rpc']))

# Replace with your private key and address
private_key = mappping[network]['pk']
my_address = mappping[network]['addr']

print(w3.eth.getTransactionCount(my_address))
print(w3.eth.get_balance(my_address))


def generate_data(prefix, size):
    tmp = []
    for i in range(size):
        s = "A" + str(i + 1)
        if i < 9:
            s = "A" + s
        tmp += [[10000 + (prefix * 100) + i + 1, s]]
    return tmp


def gen_com(n, k, current_sum=0, start=0, current_combination=[]):
    if k == 0 and current_sum == n:
        yield current_combination
        return
    if k == 0 or current_sum > n:
        return
    for i in range(start, n + 1):
        yield from gen_com(n, k - 1, current_sum + i, i, current_combination + [i])


def gen_combi_filter(n, k, max_symbols):
    com = [c[::-1] for c in list(gen_com(n, k))]
    tmp = []
    for c in com:
        if c[0] > 6:
            continue
        exceed_ms = False
        ms = (max_symbols << 1) >> 1
        for cc in c:
            if cc > ms:
                exceed_ms = True
                break
            ms = max(ms - 6, 0)
        if not exceed_ms:
            tmp += [c]
    return tmp


def encode_data_for_relay(time, request_id=1, tsArr=[]):
    data = "0xd7e7178a"
    data += eth_abi.encode_abi(['(uint256,uint256)'], [(time, request_id)]).hex()
    data += "0000000000000000000000000000000000000000000000000000000000000060"
    data += eth_abi.encode_abi(['uint256'], [len(tsArr)]).hex()
    data += eth_abi.encode_abi(['uint256'] * len(tsArr),
                               [(len(tsArr) * 32) + (i * 128) for i in range(len(tsArr))]).hex()
    for t, s in tsArr:
        data += eth_abi.encode_abi(['uint256'], [t]).hex()
        data += eth_abi.encode_abi(['uint256', 'uint256'], [64, 3]).hex()
        data += s.encode().hex() + '0000000000000000000000000000000000000000000000000000000000'
    return data


def create_tx(data):
    return {
        'to': Web3.toChecksumAddress(mappping[network]['new_std']),
        'value': 0,
        'gas': 1_000_000,
        'gasPrice': w3.toWei(mappping[network]['gp'], 'gwei'),
        'nonce': w3.eth.getTransactionCount(my_address),
        'data': data,
        'chainId': mappping[network]['chain_id']
    }


t = 155
max_symbols = 18
begin = max_symbols - 5
for j in range(begin, max_symbols + 1):
    c = gen_combi_filter(j, math.ceil(max_symbols / 6), max_symbols)
    gen_data = generate_data(j, max_symbols)
    for cc in c:
        data = []
        for i in range(len(cc)):
            offset = i * 6
            data += gen_data[offset:offset + cc[i]]

        signed_transaction = w3.eth.account.signTransaction(
            create_tx(encode_data_for_relay(t, 1, data)),
            private_key
        )
        # print(signed_transaction.rawTransaction.hex())

        transaction_hash = w3.eth.sendRawTransaction(signed_transaction.rawTransaction)
        # print(transaction_hash.hex())

        transaction_receipt = w3.eth.waitForTransactionReceipt(transaction_hash)
        if transaction_receipt["status"] == 1:
            print("time = ", t)
            print("(max_symbols, relay_amount)=", (max_symbols, j))
            print("pattern=", cc)
            print("data=", json.dumps(data).replace(" ", ""))
            print("gasUsed=", transaction_receipt["gasUsed"])
            print("transactionHash=", transaction_receipt["transactionHash"].hex())
            print("=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=")
            time.sleep(5)
            t += 1
        else:
            print(transaction_receipt)
            print("\nerror!error!error!error!error!error!error!error!error!\n")
            exit()
