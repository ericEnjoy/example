from pysui.sui.sui_clients.sync_client import SuiClient
from pysui.sui.sui_config import SuiConfig
from pysui.sui.sui_txresults.complex_tx import (
    SubscribedEvent,
    SubscribedEventParms,
    EventEnvelope,
    SubscribedTransaction,
)
from pysui.sui.sui_builders.subscription_builders import (
    SubscribeEvent,
    SubscribeTransaction,
)
from pysui.sui.sui_types.scalars import SuiString, ObjectID, SuiInteger
from pysui.sui.sui_types.collections import SuiArray


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
            package_object_id=SuiString("0xc3068e837c975ae949bffc00221c686785d09568"),
            module=SuiString("Market"),
            function=SuiString("list"),
            type_arguments=SuiArray([SuiString(collection_type_arg), SuiString(coin_type_arg)]),
            arguments=[SuiString(nft_id), SuiString(price), SuiString(marketplace)],
            gas=gases[3].identifier,
            gas_budget=SuiInteger(10000),
        )
        assert result.is_ok()
        return result

    def delist(self, collection_type_arg, coin_type_arg, listing, safe, allowlist):
        gases = self.get_gas()
        result = self.client.move_call_txn(
            signer=self.client.config.active_address,
            package_object_id=SuiString("0xc3068e837c975ae949bffc00221c686785d09568"),
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
            package_object_id=SuiString("0xc3068e837c975ae949bffc00221c686785d09568"),
            module=SuiString("Market"),
            function=SuiString("buy"),
            type_arguments=SuiArray([SuiString(collection_type_arg), SuiString(coin_type_arg)]),
            arguments=[SuiString(listing), SuiString(safe), SuiString(allowlist), SuiString(market), SuiString(collection), SuiString(wallet)],
            gas=gases[0].identifier,
            gas_budget=SuiInteger(10000),
        )
        assert result.is_ok()
        return result

    def change_price(self, coin_type_arg, listing, price):
        gases = self.get_gas()
        result = self.client.move_call_txn(
            signer=self.client.config.active_address,
            package_object_id=SuiString("0xc3068e837c975ae949bffc00221c686785d09568"),
            module=SuiString("Market"),
            function=SuiString("change_price"),
            type_arguments=SuiArray([SuiString(coin_type_arg)]),
            arguments=[SuiString(listing), SuiString(price)],
            gas=gases[3].identifier,
            gas_budget=SuiInteger(10000),
        )
        assert result.is_ok()
        return result


if __name__ == "__main__":
    cfg = SuiConfig.default()
    client = SuiClient(cfg)
    print(client.config.active_address)
    market_client = MarketClient(client)

    # result = market_client.list("0xbcae3b5adb19abf3cc3e0c693bf976ef86a87479::suimarines::SUIMARINES", "0x2::sui::SUI", "0x253b312bd7f3f12ad08278c15ea6c39e481fa51b", "1000", "0x6dce073459179eb6e495dd5086e6f4584cb2afc0")

    # result = market_client.delist("0xbcae3b5adb19abf3cc3e0c693bf976ef86a87479::suimarines::SUIMARINES", "0x2::sui::SUI", "0x94b3671a72c912a3225e058a481aab7e148d673b", "0x8c1ed864feed8234c68b311c86044b495f730776", "0xffec355efa7ccedb2df88be9218aaf29f61434c2")

    result = market_client.buy("0xbcae3b5adb19abf3cc3e0c693bf976ef86a87479::suimarines::SUIMARINES",
                               "0x2::sui::SUI",
                               "0xa2b967ed80f878f3ca8223c514f8a0235d90e8e6",
                               "0x44204221506407591e86b5392ceb3c4fe150584b",
                               "0xffec355efa7ccedb2df88be9218aaf29f61434c2",
                               "0x6dce073459179eb6e495dd5086e6f4584cb2afc0",
                               "0x303acfd3521b7a049563516a7c86c2afbdc3386d",
                               "0x80cbaa216ad42f58afd3cad49c65e3512bfb87e4"
                               )
    # result = market_client.change_price("0x2::sui::SUI", "0x77edd983ab9a5baad000f7694488469e6c6ba35f", "10000")
    print(result.is_ok())
