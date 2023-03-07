import requests
import json

url = "https://fullnode.devnet.sui.io:443"

def get_obj_type(object_id):
    payload = json.dumps({
        "jsonrpc": "2.0",
        "id": 1,
        "method": "sui_getObject",
        "params": [
            object_id
        ]
    })
    headers = {
        'Content-Type': 'application/json'
    }

    response = requests.request("POST", url, headers=headers, data=payload)
    return json.loads(response.text)["result"]["details"]["data"]["type"]

def get_obj_by_id(obj_id):
    payload = json.dumps({
        "jsonrpc": "2.0",
        "id": 1,
        "method": "sui_getObject",
        "params": [
            obj_id
        ]
    })
    headers = {
        'Content-Type': 'application/json'
    }

    response = requests.request("POST", url, headers=headers, data=payload)
    return json.loads(response.text)

def get_txn_by_id(txn_id):
    payload = json.dumps({
        "jsonrpc": "2.0",
        "id": 1,
        "method": "sui_getTransaction",
        "params": [
            txn_id
        ]
    })
    headers = {
        'Content-Type': 'application/json'
    }

    response = requests.request("POST", url, headers=headers, data=payload)
    return json.loads(response.text)

def get_shared_obj(txn_id):
    txn_ = get_txn_by_id(txn_id)
    created_objs = txn_["result"]["effects"]["created"]
    res = {}
    for obj in created_objs:
        if obj["owner"] == "Immutable":
            res["package_id"] = obj["reference"]["objectId"]
            continue
        if "Shared" in obj["owner"]:
            obj_id = obj["reference"]["objectId"]
            obj_type = get_obj_type(obj["reference"]["objectId"])
            if "mint_cap::MintCap" in obj_type:
                res["mint_cap"] = obj_id
            if "transfer_allowlist" in obj_type:
                res["transfer_allowlist"] = obj_id
            if "collection::Collection" in obj_type:
                res["collection"] = obj_id
                print(obj_type)
            continue
    return res


def get_marketplace_obj(txn_id):
    txn_ = get_txn_by_id(txn_id)
    created_objs = txn_["result"]["effects"]["created"]
    res = {}
    for obj in created_objs:
        res["marketplace"] = obj["reference"]["objectId"]

    return res

def get_nft_obj(txn_id):
    txn_ = get_txn_by_id(txn_id)
    created_objs = txn_["result"]["effects"]["created"]
    res = {}
    for obj in created_objs:
        obj_id = obj["reference"]["objectId"]
        obj_type = get_obj_type(obj["reference"]["objectId"])
        if "nft::Nft" in obj_type:
            res["nft"] = obj_id

    return res

def get_list_obj(txn_id):
    txn_ = get_txn_by_id(txn_id)
    created_objs = txn_["result"]["effects"]["created"]
    res = {}
    for obj in created_objs:
        obj_id = obj["reference"]["objectId"]
        obj_type = get_obj_type(obj["reference"]["objectId"])
        if "Market::Listing" in obj_type:
            res["listing"] = obj_id
        if "safe::OwnerCap" in obj_type:
            res['owner_cap'] = obj_id
        if "safe::Safe" in obj_type:
            res["safe"] = obj_id
    return res


if __name__ == "__main__":
    # res = get_shared_obj("328KStz3kzMVj22KjVA8JfW7NQ56wRpm8wUK4V41Pzmu")
    # print(res)
    # get_obj_info("0xd2148d10d2529e795ea81788c332548e5dc26a5b")
    # res = get_marketplace_obj("AM8rD48roWMXd3VY4q2v2NBRh477At6QTu2rjFLV6L7u")
    # print(res)
    # res = get_nft_obj("CnfJs8TtqxoCfwL8AVCmaZd82ZNGd1pDQvkGm7MjuVhw")
    # print(res)
    res = get_list_obj("HjFGATwRQECWhUR2yyZJXnWhMzE713n3FfgYnvyY7MBt")
    print(res)
