from pysui.sui.sui_clients.sync_client import SuiClient
from pysui.sui.sui_config import SuiConfig
from pysui.sui.sui_types.scalars import SuiString, ObjectID, SuiInteger
from pysui.sui.sui_types.collections import SuiArray
from util import get_shared_obj, get_marketplace_obj, get_nft_obj, get_list_obj


class MarketClient:

    def __init__(self, client):
        self.client = client

    def get_gas(self, for_address=None):
        """get_gas Utility func to refresh gas for address.
        :param client: _description_
        :type client: SuiClient
        :return: _description_
        :rtype: list[SuiGas]
        """
        result = self.client.get_gas(for_address)
        assert result.is_ok()
        # ident_list = [desc.identifier for desc in result.result_data]
        # result: SuiRpcResult = client.get_objects_for(ident_list)
        # assert result.is_ok()
        return result.result_data.data

    def list(self, collection_type_arg, coin_type_arg, nft_id, price, marketplace):
        gases = self.get_gas()
        result = self.client.move_call_txn(
            signer=self.client.config.active_address,
            package_object_id=SuiString("0xde1cc780dad75e5ec9832563bfe93c5d6359b12b"),
            module=SuiString("Market"),
            function=SuiString("list"),
            type_arguments=SuiArray([SuiString(collection_type_arg), SuiString(coin_type_arg)]),
            arguments=[SuiString(nft_id), SuiString(price), SuiString(marketplace)],
            gas=gases[0].identifier,
            gas_budget=SuiInteger(10000),
        )
        assert result.is_ok()
        return result

    def delist(self, collection_type_arg, coin_type_arg, listing, safe, allowlist):
        gases = self.get_gas()
        result = self.client.move_call_txn(
            signer=self.client.config.active_address,
            package_object_id=SuiString("0xde1cc780dad75e5ec9832563bfe93c5d6359b12b"),
            module=SuiString("Market"),
            function=SuiString("delist"),
            type_arguments=SuiArray([SuiString(collection_type_arg), SuiString(coin_type_arg)]),
            arguments=[SuiString(listing), SuiString(safe), SuiString(allowlist)],
            gas=gases[0].identifier,
            gas_budget=SuiInteger(10000),
        )
        assert result.is_ok()
        return result

    def buy(self, collection_type_arg, coin_type_arg, listing, safe, allowlist, market, collection, wallet):
        gases = self.get_gas()
        result = self.client.move_call_txn(
            signer=self.client.config.active_address,
            package_object_id=SuiString("0xde1cc780dad75e5ec9832563bfe93c5d6359b12b"),
            module=SuiString("Market"),
            function=SuiString("buy"),
            type_arguments=SuiArray([SuiString(collection_type_arg), SuiString(coin_type_arg)]),
            arguments=[SuiString(listing), SuiString(safe), SuiString(allowlist), SuiString(market), SuiString(collection), SuiArray(wallet)],
            gas=gases[0].identifier,
            gas_budget=SuiInteger(10000),
        )
        assert result.is_ok()
        return result

    def change_price(self, coin_type_arg, listing, price):
        gases = self.get_gas()
        result = self.client.move_call_txn(
            signer=self.client.config.active_address,
            package_object_id=SuiString("0xde1cc780dad75e5ec9832563bfe93c5d6359b12b"),
            module=SuiString("Market"),
            function=SuiString("change_price"),
            type_arguments=SuiArray([SuiString(coin_type_arg)]),
            arguments=[SuiString(listing), SuiString(price)],
            gas=gases[0].identifier,
            gas_budget=SuiInteger(10000),
        )
        assert result.is_ok()
        return result


if __name__ == "__main__":
    cfg = SuiConfig.default()
    client = SuiClient(cfg)
    print(client.config.active_address)
    market_client = MarketClient(client)

    collection_info = get_shared_obj("328KStz3kzMVj22KjVA8JfW7NQ56wRpm8wUK4V41Pzmu")
    marketplace_info = get_marketplace_obj("AM8rD48roWMXd3VY4q2v2NBRh477At6QTu2rjFLV6L7u")
    nft = get_nft_obj("CnfJs8TtqxoCfwL8AVCmaZd82ZNGd1pDQvkGm7MjuVhw")

    # result = market_client.list("0xae92eea71b1d19a3a3205c230facd65c876e40d0::suimarines::SUIMARINES", "0x2::sui::SUI", nft["nft"], "1000", marketplace_info["marketplace"])

    list_digest = "84fizqp53Xeo6fmLrM9JqjM5U7wmoa2c3v8AiA7Li3tx"

    list_obj = get_list_obj(list_digest)
    print(list_obj)
    result = market_client.delist(
        "0xae92eea71b1d19a3a3205c230facd65c876e40d0::suimarines::SUIMARINES",
        "0x2::sui::SUI",
        list_obj["listing"],
        list_obj["safe"],
        collection_info["transfer_allowlist"]
    )
    # client.get_gas_from_faucet(client.config.active_address)
    #
    # gases = market_client.get_gas()
    # result = market_client.buy(
    #     "0xae92eea71b1d19a3a3205c230facd65c876e40d0::suimarines::SUIMARINES",
    #     "0x2::sui::SUI",
    #     list_obj["listing"],
    #     list_obj["safe"],
    #     collection_info["transfer_allowlist"],
    #     marketplace_info["marketplace"],
    #     collection_info["collection"],
    #     [gases[2].identifier]
    # )
    # result = market_client.change_price("0x2::sui::SUI", list_obj["listing"], "2000")
    print(result.result_data)
