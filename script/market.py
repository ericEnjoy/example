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

    def list(self, type_arg, nft_id, price, marketplace):
        gases = self.get_gas()
        print(type_arg)
        result = self.client.move_call_txn(
            signer=self.client.config.active_address,
            package_object_id=SuiString("0x81e51bafbd37f96d7a1c26e67b679bb0163cf7da"),
            module=SuiString("Market"),
            function=SuiString("list"),
            type_arguments=SuiArray([SuiString(type_arg)]),
            arguments=[SuiString(nft_id), SuiString(price), SuiString(marketplace)],
            gas=gases[3].identifier,
            gas_budget=SuiInteger(10000),
        )
        assert result.is_ok()
        return result

    def delist(self, type_arg, listing, safe, allowlist):
        gases = self.get_gas()
        result = self.client.move_call_txn(
            signer=self.client.config.active_address,
            package_object_id=SuiString("0x81e51bafbd37f96d7a1c26e67b679bb0163cf7da"),
            module=SuiString("Market"),
            function=SuiString("delist"),
            type_arguments=SuiArray([SuiString(type_arg)]),
            arguments=[SuiString(listing), SuiString(safe), SuiString(allowlist)],
            gas=gases[0].identifier,
            gas_budget=SuiInteger(10000),
        )
        assert result.is_ok()
        return result

    def buy(self, type_arg, listing, safe, allowlist, market, collection, wallet):
        gases = self.get_gas()
        result = self.client.move_call_txn(
            signer=self.client.config.active_address,
            package_object_id=SuiString("0x81e51bafbd37f96d7a1c26e67b679bb0163cf7da"),
            module=SuiString("Market"),
            function=SuiString("buy"),
            type_arguments=SuiArray([SuiString(type_arg), SuiString("0x2::sui::SUI")]),
            arguments=[SuiString(listing), SuiString(safe), SuiString(allowlist), SuiString(market), SuiString(collection), SuiString(wallet)],
            gas=gases[0].identifier,
            gas_budget=SuiInteger(10000),
        )
        assert result.is_ok()
        return result

    def change_price(self, listing, price):
        gases = self.get_gas()
        result = self.client.move_call_txn(
            signer=self.client.config.active_address,
            package_object_id=SuiString("0x81e51bafbd37f96d7a1c26e67b679bb0163cf7da"),
            module=SuiString("Market"),
            function=SuiString("change_price"),
            type_arguments=SuiArray([SuiString("0x2::sui::SUI")]),
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

    # result = market_client.list("0xc11e7a3eb8b5f684545a1fdeb5290ddcf0878fde::suimarines::SUIMARINES", "0xf666bcf8dacdcc5b81d8354633428ca3246e6887", "100", "0xddff3f0e17a39125456c5813aa5127799574bbc5")

    # result = market_client.delist("0xc11e7a3eb8b5f684545a1fdeb5290ddcf0878fde::suimarines::SUIMARINES", "0xfd1030c635290523152129e2b2c8368672067715", "0x7776362f5c40058968af8d7aa4ad6902ee2eb29b", "0x9bd4e1c373f5ef81d50b5f02c46b5fbefa156216")

    # result = market_client.buy("0xc11e7a3eb8b5f684545a1fdeb5290ddcf0878fde::suimarines::SUIMARINES",
    #                            "0xf2bc1852b0c1b7c5d140ae0e4cad43943012a0e5",
    #                            "0x451b1f91ca38c101d424db732fbe2725a8457e5b",
    #                            "0x9bd4e1c373f5ef81d50b5f02c46b5fbefa156216",
    #                            "0xddff3f0e17a39125456c5813aa5127799574bbc5",
    #                            "0x510f561f2c96a3b9551a02e859c676f431531ffe",
    #                            "0xdff19375bcb7b54559094afa85ce2eca255c2097"
    #                            )
    result = market_client.change_price("0x237bd1857c089a52d3dc8bb1a2ca2783fef9dac5", "100")
    print(result.is_ok())
