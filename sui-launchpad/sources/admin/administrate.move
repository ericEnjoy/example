module sui_launchpad::administrate {

    use std::vector;
    use std::string::String;

    use sui::object::{Self, UID};
    use sui::transfer::{transfer, share_object};
    use sui::tx_context::TxContext;
    use sui::tx_context;

    use nft_protocol::nft::Nft;

    use sui_launchpad::warehouse::{Self, Warehouse, NFTContent};
    use sui_launchpad::permission::{Self, Permission};
    use sui_launchpad::workshop;
    use nft_protocol::mint_cap::{MintCap};

    friend sui_launchpad::port;

    struct Launchpad<phantom C> has key {
        id: UID,
        mint_cap: MintCap<C>,
        collection_max: u64,
        reserve: u64,
        reserve_index: u64,
        mint_index: u64,
        warehouse: Warehouse<C>
    }

    struct AdminCap<phantom C> has key {
        id: UID
    }

    public entry fun create_launchpad_with_mint_cap<C>(
        mint_cap: MintCap<C>,
        collection_max: u64,
        reserve: u64,
        ctx: &mut TxContext
    ) {
        let warehouse_ = warehouse::create_warehouse<C>(ctx);
        let launchpad = Launchpad<C> {
            id: object::new(ctx),
            mint_cap,
            collection_max,
            reserve,
            reserve_index: 1u64,
            mint_index: reserve + 1,
            warehouse: warehouse_
        };
        share_object(launchpad);
        transfer(AdminCap<C> {
            id: object::new(ctx)
        }, tx_context::sender(ctx));
    }

    public fun filling_warehouse_by_creator<C>(
        _admin_cap: &AdminCap<C>,
        launchpad: &mut Launchpad<C>,
        names: vector<String>,
        urls: vector<String>,
        symbols: vector<String>,
        attribute_keys_list: vector<vector<String>>,
        attribute_values_list: vector<vector<String>>,
    ) {
        warehouse::add_token_info(
            &mut launchpad.warehouse,
            names,
            urls,
            symbols,
            attribute_keys_list,
            attribute_values_list
        );
    }

    public entry fun filling_warehouse_by_admin<C>(
        launchpad: &mut Launchpad<C>,
        names: vector<String>,
        urls: vector<String>,
        symbols: vector<String>,
        attribute_keys_list: vector<vector<String>>,
        attribute_values_list: vector<vector<String>>,
        permission: &Permission,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        permission::check_permission(permission, sender);
        warehouse::add_token_info(
            &mut launchpad.warehouse,
            names,
            urls,
            symbols,
            attribute_keys_list,
            attribute_values_list
        );
    }

    public entry fun mint_reserve_by_creator<C>(
        _admin_cap: &AdminCap<C>,
        launchpad: &mut Launchpad<C>,
        mint_amount: u64,
        ctx: &mut TxContext
    ) {
        let reserve_index_cur = launchpad.reserve_index;
        // TODO: error unify
        assert!((reserve_index_cur + mint_amount) <= launchpad.reserve, 1);
        let i = 0;
        while(i < mint_amount) {
            let nft_content = warehouse::borrow_nft_content_mut(
                &mut launchpad.warehouse, reserve_index_cur);
            let token = mint_token<C>(nft_content, &mut launchpad.mint_cap, ctx);
            transfer(token, tx_context::sender(ctx));
            warehouse::nft_mark_as_used(nft_content);
            reserve_index_cur = reserve_index_cur + 1;
            i = i + 1;
        };
    }

    public entry fun mint_reserve_by_admin<C>(
        launchpad: &mut Launchpad<C>,
        mint_amount: u64,
        permission: &Permission,
        ctx: &mut TxContext
    ) {
        permission::check_permission(permission, tx_context::sender(ctx));
        let reserve_index_cur = launchpad.reserve_index;
        // TODO: error unify
        assert!((reserve_index_cur + mint_amount) <= launchpad.reserve, 1);
        let i = 0;
        while(i < mint_amount) {
            let nft_content = warehouse::borrow_nft_content_mut(
                &mut launchpad.warehouse, reserve_index_cur);
            let token = mint_token<C>(nft_content, &mut launchpad.mint_cap, ctx);
            transfer(token, tx_context::sender(ctx));
            warehouse::nft_mark_as_used(nft_content);
            reserve_index_cur = reserve_index_cur + 1;
            i = i + 1;
        };
    }

    public(friend) fun sale_mint<C>(
        launchpad: &mut Launchpad<C>,
        mint_amount: u64,
        ctx: &mut TxContext
    ): vector<Nft<C>> {
        // TODO: assert sender with permission
        let reserve_index_cur = launchpad.reserve_index;
        // TODO: error unify
        assert!((reserve_index_cur + mint_amount) <= launchpad.reserve, 1);
        let i = 0;
        let nfts = vector::empty<Nft<C>>();
        while(i < mint_amount) {
            let nft_content = warehouse::borrow_nft_content_mut(
                &mut launchpad.warehouse, reserve_index_cur);
            let token = mint_token<C>(nft_content, &mut launchpad.mint_cap, ctx);
            vector::push_back(&mut nfts, token);
            warehouse::nft_mark_as_used(nft_content);
            reserve_index_cur = reserve_index_cur + 1;
            i = i + 1;
        };
        nfts
    }

    fun mint_token<C>(nft_content: &NFTContent, mint_cap: &mut MintCap<C>, ctx: &mut TxContext): Nft<C> {
        workshop::mint_token(nft_content, mint_cap, ctx)
    }

    public entry fun post_sale_mint_by_creator<C>(
        _admin_cap: &AdminCap<C>,
        _launchpad: &mut Launchpad<C>,
    ) {}

    public entry fun post_sale_mint_by_admin<C, MintType: store>() {}

    public entry fun update_sale_plan_time<C, MintType>() {

    }

    public entry fun update_sale_plan_name<C, MintType>() {}

}