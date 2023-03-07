module sui_launchpad::administrate {

    use std::vector;
    use std::option::{Self, Option};
    use std::string::String;

    use sui::object::{Self, UID};
    use sui::transfer::{transfer, share_object};
    use sui::tx_context::TxContext;
    use sui::tx_context;

    use nft_protocol::nft::Nft;

    use sui_launchpad::warehouse::{Self, Warehouse, NFTContent};
    use sui_launchpad::permission::{Self, Permission};
    use sui_launchpad::workshop;
    use nft_protocol::mint_cap::{UnregulatedMintCap, RegulatedMintCap};
    use sui_launchpad::computing_room::{Self, Maze};

    friend sui_launchpad::port;

    struct Launchpad<phantom C> has key {
        id: UID,
        mint_cap: MintCap<C>,
        collection_max: u64,
        reserve: u64,
        reserve_index: u64,
        mint_index: u64,
        warehouse: Warehouse<C>,
        paper: Maze
    }

    struct MintCap<phantom C> has store {
        mint_type: u8,
        unregulated_mint_cap: Option<UnregulatedMintCap<C>>,
        regulated_mint_cap: Option<RegulatedMintCap<C>>
    }

    struct AdminCap<phantom C> has key, store {
        id: UID
    }

    public fun create_launchpad_with_unregulated_cap<C>(
        mint_cap: UnregulatedMintCap<C>,
        collection_max: u64,
        reserve: u64,
        does_sequential: bool,
        ctx: &mut TxContext
    ): AdminCap<C> {
        let warehouse_ = warehouse::create_warehouse<C>(ctx);
        let mint_cap_ = MintCap<C> {
            mint_type: 2,
            unregulated_mint_cap: option::some(mint_cap),
            regulated_mint_cap: option::none<RegulatedMintCap<C>>()
        };
        let paper = computing_room::create_maze(does_sequential, collection_max);
        let launchpad = Launchpad<C> {
            id: object::new(ctx),
            mint_cap: mint_cap_,
            collection_max,
            reserve,
            reserve_index: 1u64,
            mint_index: reserve + 1,
            warehouse: warehouse_,
            paper
        };
        share_object(launchpad);
        AdminCap<C> {
            id: object::new(ctx)
        }
    }

    public fun create_launchpad_with_regulated_cap<C>(
        mint_cap: RegulatedMintCap<C>,
        collection_max: u64,
        reserve: u64,
        does_sequential: bool,
        ctx: &mut TxContext
    ): AdminCap<C> {
        let warehouse_ = warehouse::create_warehouse<C>(ctx);
        let mint_cap_ = MintCap<C> {
            mint_type: 1,
            unregulated_mint_cap: option::none<UnregulatedMintCap<C>>(),
            regulated_mint_cap: option::some(mint_cap)
        };
        let paper = computing_room::create_maze(does_sequential, collection_max);
        let launchpad = Launchpad<C> {
            id: object::new(ctx),
            mint_cap: mint_cap_,
            collection_max,
            reserve,
            reserve_index: 1u64,
            mint_index: reserve + 1,
            warehouse: warehouse_,
            paper
        };
        share_object(launchpad);
        AdminCap<C> {
            id: object::new(ctx)
        }
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
        let sender = tx_context::sender(ctx);
        // TODO: error unify
        assert!((reserve_index_cur + mint_amount) <= launchpad.reserve, 1);
        let i = 0;
        while(i < mint_amount) {
            let remaining = get_remaining(
                launchpad.collection_max,
                launchpad.reserve,
                launchpad.reserve_index,
                reserve_index_cur
            );
            let mint_index = computing_room::get_mint_index(&mut launchpad.paper, remaining, reserve_index_cur, sender);
            let nft_content = warehouse::borrow_nft_content_mut(
                &mut launchpad.warehouse, mint_index);
            let token = mint_token<C>(nft_content, &mut launchpad.mint_cap, ctx);
            transfer(token, tx_context::sender(ctx));
            warehouse::nft_mark_as_used(nft_content);
            reserve_index_cur = reserve_index_cur + 1;
            i = i + 1;
        };
        launchpad.reserve_index = reserve_index_cur;
    }

    public entry fun mint_reserve_by_admin<C>(
        launchpad: &mut Launchpad<C>,
        mint_amount: u64,
        permission: &Permission,
        ctx: &mut TxContext
    ) {
        permission::check_permission(permission, tx_context::sender(ctx));
        let sender = tx_context::sender(ctx);
        let reserve_index_cur = launchpad.reserve_index;
        // TODO: error unify
        assert!((reserve_index_cur + mint_amount) <= launchpad.reserve, 1);
        let i = 0;
        while(i < mint_amount) {
            let remaining = get_remaining(
                launchpad.collection_max,
                launchpad.reserve,
                launchpad.reserve_index,
                reserve_index_cur
            );
            let mint_index = computing_room::get_mint_index(&mut launchpad.paper, remaining, reserve_index_cur, sender);
            let nft_content = warehouse::borrow_nft_content_mut(
                &mut launchpad.warehouse, mint_index);
            let token = mint_token<C>(nft_content, &mut launchpad.mint_cap, ctx);
            transfer(token, tx_context::sender(ctx));
            warehouse::nft_mark_as_used(nft_content);
            reserve_index_cur = reserve_index_cur + 1;
            i = i + 1;
        };
        launchpad.reserve_index = reserve_index_cur;
    }

    public(friend) fun sale_mint<C>(
        launchpad: &mut Launchpad<C>,
        mint_amount: u64,
        ctx: &mut TxContext
    ): vector<Nft<C>> {
        let sender = tx_context::sender(ctx);
        let mint_index_cur = launchpad.mint_index;
        // TODO: error unify
        assert!((mint_index_cur + mint_amount) <= (launchpad.collection_max - launchpad.reserve), 1);
        let i = 0;
        let nfts = vector::empty<Nft<C>>();
        while(i < mint_amount) {
            let remaining = get_remaining(
                launchpad.collection_max,
                launchpad.reserve,
                launchpad.reserve_index,
                mint_index_cur
            );
            let mint_index = computing_room::get_mint_index(&mut launchpad.paper, remaining, mint_index_cur, sender);
            let nft_content = warehouse::borrow_nft_content_mut(
                &mut launchpad.warehouse, mint_index);
            let token = mint_token<C>(nft_content, &mut launchpad.mint_cap, ctx);
            vector::push_back(&mut nfts, token);
            warehouse::nft_mark_as_used(nft_content);
            mint_index_cur = mint_index_cur + 1;
            i = i + 1;
        };
        launchpad.mint_index = mint_index_cur;
        nfts
    }

    fun mint_token<C>(nft_content: &NFTContent, mint_cap: &mut MintCap<C>, ctx: &mut TxContext): Nft<C> {
        // TODO: error unify
        assert!(mint_cap.mint_type < 3, 1);
        if(mint_cap.mint_type == 1) {
            let cap_ = option::borrow_mut(&mut mint_cap.regulated_mint_cap);
            workshop::mint_token_with_regulated(nft_content, cap_, ctx)
        } else {
            let cap_ = option::borrow(&mint_cap.unregulated_mint_cap);
            workshop::mint_token_with_unregulated(nft_content, cap_, ctx)
        }
    }

    public entry fun post_sale_mint_by_creator<C>(
        _admin_cap: &AdminCap<C>,
        _launchpad: &mut Launchpad<C>,
    ) {}

    public entry fun post_sale_mint_by_admin<C, MintType: store>() {}

    public entry fun update_sale_plan_time<C, MintType>() {

    }

    public entry fun update_sale_plan_name<C, MintType>() {}

    fun get_remaining(max: u64, reserve: u64, reserve_index: u64, mint_index: u64): u64 {
        max - (reserve_index - 1) - (mint_index - reserve - 1)
    }

}