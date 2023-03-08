#[test_only]
module sui_launchpad::test_launch {

    use std::string;

    use sui::object;
    use sui::balance;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    use nft_protocol::tags;
    use nft_protocol::royalty;
    use nft_protocol::display;
    use nft_protocol::witness;
    use nft_protocol::creators;
    use nft_protocol::transfer_allowlist;
    use nft_protocol::royalties::{Self, TradePayment};
    use nft_protocol::collection::{Self, Collection};
    use nft_protocol::transfer_allowlist_domain;
    use nft_protocol::supply_domain;

    use sui_launchpad::administrate;
    use sui_launchpad::port;

    struct Gekacha has drop {}

    /// Can be used for authorization of other actions post-creation. It is
    /// vital that this struct is not freely given to any contract, because it
    /// serves as an auth token.
    struct Witness has drop, store {}

    #[test_only]
    public fun create(witness: Witness, ctx: &mut TxContext): (AdminCap<Gekacha>, Launchpad<Gekacha>) {
        let sender = tx_context::sender(ctx);
        let collection_max = 1000u64;
        let collection_reserve = 0u64;

        let (mint_cap, collection) = collection::create(&Gekacha {}, ctx);

        collection::add_domain(
            &Witness {},
            &mut collection,
            creators::from_address<Gekacha, Witness>(
                &Witness {}, sender,
            ),
        );

        // Register custom domains
        display::add_collection_display_domain(
            &Witness {},
            &mut collection,
            string::utf8(b"Gekacha"),
            string::utf8(b"The best NFT collection of Gekacha on Sui"),
        );

        display::add_collection_url_domain(
            &Witness {},
            &mut collection,
            sui::url::new_unsafe_from_bytes(b"https://gekacha.io/"),
        );

        display::add_collection_symbol_domain(
            &Witness {},
            &mut collection,
            string::utf8(b"GKC"),
        );

        supply_domain::regulate(&witness, &mut collection, collection_max, true);

        let royalty = royalty::from_address(sender, ctx);
        royalty::add_proportional_royalty(&mut royalty, 100);
        royalty::add_royalty_domain(&Witness {}, &mut collection, royalty);

        let tags = tags::empty(ctx);
        tags::add_tag(&mut tags, tags::art());
        tags::add_collection_tag_domain(&Witness {}, &mut collection, tags);

        let allowlist = transfer_allowlist::create(&Witness {}, ctx);
        transfer_allowlist::insert_collection<Gekacha, Witness>(
            &Witness {},
            witness::from_witness(&Witness {}),
            &mut allowlist,
        );

        collection::add_domain(
            &Witness {},
            &mut collection,
            transfer_allowlist_domain::from_id(object::id(&allowlist)),
        );

        let regulated_mint_cap = supply_domain::delegate(&mint_cap, &mut collection, 1000, ctx);

        let (admin_cap, launchpad) = administrate::test_create_launchpad_with_regulated_cap(
            regulated_mint_cap,
            collection_max,
            collection_reserve,
            true,
            ctx
        );

        transfer::transfer(mint_cap, tx_context::sender(ctx));
        transfer::share_object(allowlist);
        transfer::share_object(collection);
        (admin_cap, launchpad)
    }

    /// Calculates and transfers royalties to the `RoyaltyDomain`
    public entry fun collect_royalty<FT>(
        payment: &mut TradePayment<Gekacha, FT>,
        collection: &mut Collection<Gekacha>,
        ctx: &mut TxContext
    ) {
        let b = royalties::balance_mut(Witness {}, payment);

        let domain = royalty::royalty_domain(collection);
        let royalty_owed =
            royalty::calculate_proportional_royalty(domain, balance::value(b));

        royalty::collect_royalty(collection, b, royalty_owed);
        royalties::transfer_remaining_to_beneficiary(Witness {}, payment, ctx);
    }

    const OWNER: address = @0x2;
    const FAKE_OWNER: address = @0xA1C11;

    use sui::test_scenario::{Self, ctx};
    use sui_launchpad::administrate::{filling_warehouse_by_creator, AdminCap, Launchpad};
    use sui_launchpad::plan;

    #[test]
    fun test_create() {
        let scenario = test_scenario::begin(OWNER);
        let ctx = ctx(&mut scenario);
        let (admin_cap, launchpad) = create(Witness {}, ctx);
        transfer::transfer(admin_cap, OWNER);
        transfer::transfer(launchpad, OWNER);

        test_scenario::end(scenario);
    }

    #[test]
    fun test_filling_warehouse() {
        let scenario = test_scenario::begin(OWNER);
        let ctx = ctx(&mut scenario);
        let (admin_cap, launchpad) = create(Witness {}, ctx);
        filling_warehouse_by_creator(
            &admin_cap,
            &mut launchpad,
            vector[string::utf8(b"GG #1"), string::utf8(b"GG #2")],
            vector[string::utf8(b"https://1"), string::utf8(b"https://2")],
            vector[string::utf8(b"G1"), string::utf8(b"G2")],
            vector[],
            vector[]
        );
        transfer::transfer(admin_cap, OWNER);
        transfer::transfer(launchpad, OWNER);

        test_scenario::end(scenario);
    }

    #[test]
    fun test_create_sale_plan() {
        use sui::sui::SUI;
        use sui::clock::{Self};
        use sui::coin::{Self};
        let scenario = test_scenario::begin(OWNER);
        let ctx_ = ctx(&mut scenario);
        let (admin_cap, launchpad) = create(Witness {}, ctx_);
        filling_warehouse_by_creator(
            &admin_cap,
            &mut launchpad,
            vector[string::utf8(b"GG #1"), string::utf8(b"GG #2")],
            vector[string::utf8(b"https://1"), string::utf8(b"https://2")],
            vector[string::utf8(b"G1"), string::utf8(b"G2")],
            vector[],
            vector[]
        );
        let sale_plan = plan::test_create_sale_plan<Gekacha, SUI>(
            &admin_cap,
            1,
            vector[OWNER, OWNER],
            vector[10, 20],
            ctx_
        );
        plan::add_plan<Gekacha, SUI>(
            &admin_cap,
            &mut sale_plan,
            string::utf8(b"Pre Sale I"),
            100,
            0,
            1000,
            false,
            0,
            100,
            2,
            ctx_
        );
        let clock_ = clock::create_for_testing(10);
        let wallet = coin::mint_for_testing<SUI>(1000, ctx_);
        port::sale_mint(
            &mut launchpad,
            &mut sale_plan,
            0,
            1,
            vector<u8>[],
            vector[wallet],
            &clock_,
            ctx_
        );

        transfer::transfer(admin_cap, OWNER);
        transfer::transfer(launchpad, OWNER);
        transfer::transfer(sale_plan, OWNER);

        clock::delete_for_testing(clock_);
        test_scenario::end(scenario);
    }
}