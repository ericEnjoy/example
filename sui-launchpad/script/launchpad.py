from pysui.sui.sui_clients.sync_client import SuiClient
from pysui.sui.sui_config import SuiConfig
from pysui.sui.sui_types.scalars import SuiString, ObjectID, SuiInteger
from pysui.sui.sui_types.collections import SuiArray


class sui_launchpad:

    def __init__(self, client):
        self.contract_address = "0xfdfe8940223686b8967fdae16e6d824808bab85d"
        self.client = client

    # def create_with_unregulated_cap(self, unregulated_mint_cap, collection_max, reserve, does_sequential):
    #     gases = self.get_gas()
    #     result = self.client.move_call_txn(
    #         signer=self.client.config.active_address,
    #         package_object_id=SuiString(self.contract_address),
    #         module=SuiString("administrate"),
    #         function=SuiString("create_launchpad_with_unregulated_cap"),
    #         type_arguments=SuiArray([SuiString(collection_type_arg), SuiString(coin_type_arg)]),
    #         arguments=[SuiString(nft_id), SuiString(price), SuiString(marketplace)],
    #         gas=gases[0].identifier,
    #         gas_budget=SuiInteger(10000),
    #     )
    #     assert result.is_ok()
    #     return result
    #
    # def create_with_regulated_mint_cap(self, regulated_mint_cap):
    #     gases = self.get_gas()
    #     result = self.client.move_call_txn(
    #         signer=self.client.config.active_address,
    #         package_object_id=SuiString(self.contract_address),
    #         module=SuiString("Market"),
    #         function=SuiString("list"),
    #         type_arguments=SuiArray([SuiString(collection_type_arg), SuiString(coin_type_arg)]),
    #         arguments=[SuiString(nft_id), SuiString(price), SuiString(marketplace)],
    #         gas=gases[0].identifier,
    #         gas_budget=SuiInteger(10000),
    #     )
    #     assert result.is_ok()
    #     return result
    #
    #     pass

    def filling_warehouse_by_creator(self, admin_cap, collection_type, launchpad,
                                     names, urls, symbols, attr_keys, attr_values):
        gases = self.get_gas()
        result = self.client.move_call_txn(
            signer=self.client.config.active_address,
            package_object_id=SuiString(self.contract_address),
            module=SuiString("administrate"),
            function=SuiString("filling_warehouse_by_creator"),
            type_arguments=SuiArray([SuiString(collection_type)]),
            arguments=[
                SuiString(admin_cap), SuiString(launchpad), SuiArray(names), SuiArray(urls),
                SuiArray(symbols), SuiArray(attr_keys), SuiArray(attr_values)
            ],
            gas=gases[0].identifier,
            gas_budget=SuiInteger(10000),
        )
        assert result.is_ok()
        return result

    def filling_warehouse_by_admin(self, permission, collection_type, launchpad, names, urls, symbols, attr_keys, attr_values):
        gases = self.get_gas()
        result = self.client.move_call_txn(
            signer=self.client.config.active_address,
            package_object_id=SuiString(self.contract_address),
            module=SuiString("administrate"),
            function=SuiString("filling_warehouse_by_admin"),
            type_arguments=SuiArray([SuiString(collection_type)]),
            arguments=[
                SuiString(launchpad), SuiArray(names), SuiArray(urls),
                SuiArray(symbols), SuiArray(attr_keys), SuiArray(attr_values), SuiString(permission)
            ],
            gas=gases[0].identifier,
            gas_budget=SuiInteger(10000),
        )
        assert result.is_ok()
        return result

    def create_sale_plan(self):
        pass

    def add_sale_plan(self):
        pass

    def sale_mint(self, collection_type, coin_type, launchpad, sale_plan, plan_index, mint_amount, sig, wallet, clock):
        gases = self.get_gas()
        result = self.client.move_call_txn(
            signer=self.client.config.active_address,
            package_object_id=SuiString(self.contract_address),
            module=SuiString("port"),
            function=SuiString("sale_mint"),
            type_arguments=SuiArray([SuiString(collection_type), SuiString(coin_type)]),
            arguments=[
                SuiString(launchpad), SuiString(sale_plan), SuiString(plan_index), SuiString(mint_amount), SuiArray(sig),
                SuiArray(wallet), SuiString(clock)
            ],
            gas=gases[0].identifier,
            gas_budget=SuiInteger(10000),
        )
        assert result.is_ok()
        return result
