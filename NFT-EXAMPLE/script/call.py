from pysui.sui.sui_clients.sync_client import SuiClient
from pysui.sui.sui_config import SuiConfig
from pysui.sui.sui_types.scalars import SuiString, ObjectID, SuiInteger
from pysui.sui.sui_types.collections import SuiArray

def get_gas(client, for_address=None):
    """get_gas Utility func to refresh gas for address.
    :param client: _description_
    :type client: SuiClient
    :return: _description_
    :rtype: list[SuiGas]
    """
    result = client.get_gas(for_address)
    assert result.is_ok()
    # ident_list = [desc.identifier for desc in result.result_data]
    # result: SuiRpcResult = client.get_objects_for(ident_list)
    # assert result.is_ok()
    return result.result_data.data


cfg = SuiConfig.default()
client = SuiClient(cfg)
gases = get_gas(client)
print(gases)
print(client.config.active_address)

result = client.move_call_txn(
    signer=client.config.active_address,
    package_object_id=SuiString("0xae92eea71b1d19a3a3205c230facd65c876e40d0"),
    module=SuiString("suimarines"),
    function=SuiString("mint_nft"),
    type_arguments=SuiArray([]),
    arguments=[SuiString("name"), SuiString("description"), SuiString("https://static.souffl3.com/token-image/NzTteL9KnDKvP25BEgw9LM77rQgPkMR6E2RkuuGejY5G8ckv4UcZz3s9fEPjMPMkbWYybupeSH7xjJmkCjma1TsZy"), SuiArray(["key"]), SuiArray(["val"]), ObjectID("0xd2148d10d2529e795ea81788c332548e5dc26a5b")],
    gas=gases[0].identifier,

    gas_budget=SuiInteger(10000),
)

print(result.is_ok())

# result = client.move_call_txn(
#     signer=client.config.active_address,
#     package_object_id=SuiString("0xce5c7d026f080e57a48cadb1b0b023ada602e4d3"),
#     module=SuiString("suimarines"),
#     function=SuiString("mint_nft"),
#     type_arguments=SuiArray([]),
#     arguments=[SuiString("name"), SuiString("description"), SuiString("1"), SuiArray(["key"]), SuiArray(["val"]), SuiString("0x2edb77eb18a8980ed56612567530fdf2b02ede4f"), SuiString("0x4a46f10fe5e3ec2a278a20bdb31cdbe0ae70a60f")],
#     gas=gases[0].identifier,
#     gas_budget=SuiInteger(10000),
# )
