module sui_launchpad::warehouse {

    use std::string::{Self, String};
    use std::option::{Self, Option};

    use sui::url::{Self, Url};
    use sui::table_vec::{Self, TableVec};
    use sui::tx_context::TxContext;
    use std::vector;

    friend sui_launchpad::administrate;

    struct Warehouse<phantom C> has store {
        collection_info: Option<CollectionContent>,
        nft_content: TableVec<NFTContent>
    }

    struct CollectionContent has store, drop {
        name: String,
        url: Url,
        symbol: String,
        description: Option<String>,
        creators: vector<address>,
        is_used: bool
    }

    struct NFTContent has store, drop {
        name: String,
        url: Url,
        symbol: Option<String>,
        attribute_keys: vector<String>,
        attribute_values: vector<String>,
        is_used: bool
    }

    public fun create_warehouse<C>(
        ctx: &mut TxContext
    ): Warehouse<C>{
        Warehouse<C> {
            collection_info: option::none<CollectionContent>(),
            nft_content: table_vec::empty(ctx)
        }
    }

    public(friend) fun add_token_info<C>(
        warehouse: &mut Warehouse<C>,
        names: vector<String>,
        urls: vector<String>,
        symbols: vector<String>,
        attribute_keys_list: vector<vector<String>>,
        attribute_values_list: vector<vector<String>>
    ) {
        let len = vector::length(&names);
        let i = 0;
        let symbol_flag = if (vector::length(&symbols) == len) {
            true
        } else {
            false
        };
        let attribute_flag = if (vector::length(&attribute_keys_list) == len) {
            true
        } else {
            false
        };
        while (i < len) {
            let name = vector::pop_back(&mut names);
            let url_string = vector::pop_back(&mut urls);
            let url_ = url::new_unsafe(string::to_ascii(url_string));
            let symbol = if (symbol_flag) {
                option::some<String>(vector::pop_back(&mut symbols))
            } else {
                option::none<String>()
            };
            let attribute_keys = if (attribute_flag) {
                vector::pop_back(&mut attribute_keys_list)
            } else {
                vector::empty<String>()
            };
            let attribute_values = if (attribute_flag) {
                vector::pop_back(&mut attribute_values_list)
            } else {
                vector::empty<String>()
            };
            let nft_content = NFTContent {
                name,
                url: url_,
                symbol,
                attribute_keys,
                attribute_values,
                is_used: false
            };
            table_vec::push_back(&mut warehouse.nft_content, nft_content);
            i = i + 1;
        }
    }

    public fun borrow_nft_content_mut<C>(
        warehouse: &mut Warehouse<C>,
        index: u64
    ): &mut NFTContent{
        table_vec::borrow_mut(&mut warehouse.nft_content, index)
    }

    public fun nft_mark_as_used(
        nft_content: &mut NFTContent
    ) {
        nft_content.is_used = true;
    }

    public fun get_nft_name(nft_content: &NFTContent): String {
        nft_content.name
    }

    public fun get_nft_url(nft_content: &NFTContent): Url {
        nft_content.url
    }

    public fun get_nft_symbol(nft_content: &NFTContent): (bool, String) {
        let contain = false;
        let symbol = string::utf8(b"");
        if (option::is_some(&nft_content.symbol)) {
            contain = true;
            symbol = *option::borrow(&nft_content.symbol);
        };
        (contain, symbol)
    }

    public fun get_nft_attributes_keys(nft_content: &NFTContent): (bool, vector<String>) {
        let contain = false;
        let attributes_keys = vector::empty<String>();
        if (!vector::is_empty(&nft_content.attribute_keys)) {
            contain = true;
            attributes_keys = nft_content.attribute_keys;
        };
        (contain, attributes_keys)
    }

    public fun get_nft_attributes_values(nft_content: &NFTContent): (bool, vector<String>) {
        let contain = false;
        let attributes_values = vector::empty<String>();
        if (!vector::is_empty(&nft_content.attribute_values)) {
            contain = true;
            attributes_values = nft_content.attribute_values;
        };
        (contain, attributes_values)
    }


}
