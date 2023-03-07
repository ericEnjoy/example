#[test_only]
module sui_launchpad::launch {

    use std::string::{Self, String};

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

    use sui_launchpad::administrate;

    struct Gekacha has drop {}

    /// Can be used for authorization of other actions post-creation. It is
    /// vital that this struct is not freely given to any contract, because it
    /// serves as an auth token.
    struct Witness has drop {}

    fun init(witness: Gekacha, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        let collection_max = 1000u64;
        let collection_reserve = 100u64;

        let (mint_cap, collection) = collection::create(&witness, ctx);

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

        administrate::create_launchpad_with_mint_cap(mint_cap, collection_max, collection_reserve, ctx);

        transfer::share_object(allowlist);
        transfer::share_object(collection);
    }

    /// Calculates and transfers royalties to the `RoyaltyDomain`
    public entry fun collect_royalty<FT>(
        payment: &mut TradePayment<Gekacha, FT>,
        collection: &mut Collection<Gekacha>,
        ctx: &mut TxContext,
    ) {
        let b = royalties::balance_mut(Witness {}, payment);

        let domain = royalty::royalty_domain(collection);
        let royalty_owed =
        royalty::calculate_proportional_royalty(domain, balance::value(b));

        royalty::collect_royalty(collection, b, royalty_owed);
        royalties::transfer_remaining_to_beneficiary(Witness {}, payment, ctx);
    }
}