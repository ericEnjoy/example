module Souffl3::Market {

    use std::option::{Self, Option};

    use sui::event;
    use sui::coin::{Self, Coin};
    use sui::transfer::{Self, share_object, transfer};
    use sui::object::{Self, ID , UID};
    use sui::tx_context::{Self, TxContext};

    use nft_protocol::royalty;
    use nft_protocol::nft::Nft;
    use nft_protocol::collection::Collection;
    use nft_protocol::safe::{Self, Safe, TransferCap};
    use nft_protocol::transfer_allowlist::{Allowlist};

    use Souffl3::marketplace::{Self, MarketPlace};

    struct Witness has drop {}

    struct Listing<phantom FT> has key, store {
        id: UID,
        nft: ID,
        safe: ID,
        seller: address,
        price: u64,
        market_id: ID,
        transfer_cap: Option<TransferCap>,
        is_generic: bool
    }

    struct ListEvent<phantom FT> has copy, drop {
        seller: address,
        nft_id: ID,
        safe_id: ID,
        price: u64,
        marketplace: ID,
    }

    struct DelistEvent<phantom FT> has copy, drop {
        seller: address,
        nft_id: ID,
        safe_id: ID,
        marketplace: ID
    }

    struct ChangePriceEvent<phantom FT> has copy, drop {
        seller: address,
        nft_id: ID,
        safe_id: ID,
        marketplace: ID,
        old_price: u64,
        new_price: u64

    }

    struct BuyEvent<phantom FT> has copy, drop {
        seller: address,
        buyer: address,
        nft_id: ID,
        safe_id: ID,
        marketplace: ID,
        price: u64
    }

    public entry fun list<C, FT>(
        nft: Nft<C>,
        price: u64,
        market: &MarketPlace,
        ctx: &mut TxContext
    ) {
        let nft_id = *object::borrow_id(&nft);
        // create_safe_with_nft
        let (safe_, cap) = safe::new(ctx);
        let safe_id = safe::owner_cap_safe(&cap);
        safe::deposit_nft(nft, &mut safe_, ctx);
        // create_listing_with_safe_id
        // get market_id from Market
        let market_id = *object::borrow_id(market);
        // get nft_id from NFT
        // get transfer cap from safe (not exclusive
        let transfer_cap = safe::create_transfer_cap(nft_id, &cap, &mut safe_, ctx);
        let some_transfer_cap = option::some(transfer_cap);
        let seller = tx_context::sender(ctx);

        let listing = Listing<FT> {
            id: object::new(ctx),
            nft: nft_id,
            safe: safe_id,
            seller,
            price,
            market_id,
            transfer_cap: some_transfer_cap,
            is_generic: false
        };
        // share listing
        share_object(listing);
        share_object(safe_);
        transfer::transfer(cap, tx_context::sender(ctx));

        event::emit(ListEvent<FT> {
            seller,
            nft_id,
            safe_id,
            price,
            marketplace: market_id
        })
    }

    public entry fun list_generic<T: key + store, FT>(
        nft: T,
        price: u64,
        market: &MarketPlace,
        ctx: &mut TxContext
    ) {
        let nft_id = *object::borrow_id(&nft);
        // create_safe_with_nft
        let (safe_, cap) = safe::new(ctx);
        let safe_id = safe::owner_cap_safe(&cap);
        safe::deposit_generic_nft(nft, &mut safe_, ctx);
        // create_listing_with_safe_id
        // get market_id from Market
        let market_id = *object::borrow_id(market);
        // get nft_id from NFT
        // get transfer cap from safe (not exclusive
        let transfer_cap = safe::create_transfer_cap(nft_id, &cap, &mut safe_, ctx);
        let some_transfer_cap = option::some(transfer_cap);
        let seller = tx_context::sender(ctx);

        let listing = Listing<FT> {
            id: object::new(ctx),
            nft: nft_id,
            safe: safe_id,
            seller,
            price,
            market_id,
            transfer_cap: some_transfer_cap,
            is_generic: false
        };
        // share listing
        share_object(listing);
        share_object(safe_);
        transfer::transfer(cap, tx_context::sender(ctx));

        event::emit(ListEvent<FT> {
            seller,
            nft_id,
            safe_id,
            price,
            marketplace: market_id
        })
    }

    public entry fun delist<C, FT>(
        listing: &mut Listing<FT>,
        safe: &mut Safe,
        allowlist: &Allowlist,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(sender == listing.seller, 2);
        let seller = listing.seller;
        let transfer_cap = extract_transfer_cap_from_listing(listing);
        safe::transfer_nft_to_recipient<C, Witness>(transfer_cap, seller, Witness{}, allowlist, safe);
        event::emit(DelistEvent<FT> {
            seller,
            nft_id: listing.nft,
            safe_id: listing.safe,
            marketplace: listing.market_id
        })
    }

    public entry fun delist_generic<T: key + store, FT>(
        listing: &mut Listing<FT>,
        safe: &mut Safe,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(sender == listing.seller, 2);
        let seller = listing.seller;
        let transfer_cap = extract_transfer_cap_from_listing(listing);
        safe::transfer_generic_nft_to_recipient<T>(transfer_cap, seller, safe);
        event::emit(DelistEvent<FT> {
            seller,
            nft_id: listing.nft,
            safe_id: listing.safe,
            marketplace: listing.market_id
        })
    }

    public entry fun buy<C, FT>(
        listing: &mut Listing<FT>,
        seller_safe: &mut Safe,
        allowlist: &Allowlist,
        market: &MarketPlace,
        collection: &mut Collection<C>,
        wallet: &mut Coin<FT>,
        ctx: &mut TxContext
    ) {
        let balance_mut = coin::balance_mut(wallet);
        // transfer market fee to beneficiary
        let market_fee = marketplace::calc_market_fee(market, listing.price);
        transfer(
            coin::take(
                balance_mut,
                market_fee,
                ctx,
            ),
            marketplace::get_beneficiary(market)
        );
        // calc royalty and transfer royalty to beneficiary
        let domain = royalty::royalty_domain(collection);
        let royalty_owed =
            royalty::calculate_proportional_royalty(domain, listing.price);
        royalty::collect_royalty(collection, balance_mut, royalty_owed);

        let remaining = listing.price - royalty_owed - market_fee;
        // safe::transfer_nft_to_safe with transfer_cap in listing
        let remaining_balance = coin::take(balance_mut, remaining, ctx);
        transfer(
            remaining_balance,
            listing.seller
        );

        let seller = listing.seller;
        let buyer = tx_context::sender(ctx);
        let transfer_cap = extract_transfer_cap_from_listing(listing);
        safe::transfer_nft_to_recipient<C, Witness>(transfer_cap, seller, Witness{}, allowlist, seller_safe);

        event::emit(BuyEvent<FT> {
            seller,
            buyer,
            nft_id: listing.nft,
            safe_id: listing.safe,
            marketplace: listing.market_id,
            price: listing.price
        })
    }

    public entry fun buy_generic<T: key + store, FT>(
        listing: &mut Listing<FT>,
        seller_safe: &mut Safe,
        market: &MarketPlace,
        wallet: &mut Coin<FT>,
        ctx: &mut TxContext
    ) {
        let balance_mut = coin::balance_mut(wallet);
        // transfer market fee to beneficiary
        let market_fee = marketplace::calc_market_fee(market, listing.price);
        transfer(
            coin::take(
                balance_mut,
                market_fee,
                ctx,
            ),
            marketplace::get_beneficiary(market)
        );
        // transfer market fee to marketplace
        let remaining = listing.price - market_fee;
        // transfer remaining coin to seller
        let remaining_balance = coin::take(balance_mut, remaining, ctx);
        transfer(
            remaining_balance,
            listing.seller
        );
        let seller = listing.seller;
        let buyer = tx_context::sender(ctx);
        let transfer_cap = extract_transfer_cap_from_listing(listing);
        safe::transfer_generic_nft_to_recipient<T>(transfer_cap, seller, seller_safe);

        event::emit(BuyEvent<FT> {
            seller,
            buyer,
            nft_id: listing.nft,
            safe_id: listing.safe,
            marketplace: listing.market_id,
            price: listing.price
        })
    }

    public entry fun change_price<FT>(
        listing: &mut Listing<FT>,
        price: u64,
        ctx: &mut TxContext
    ) {
        // assert listing.seller is signer
        let sender = tx_context::sender(ctx);
        let seller = listing.seller;
        let old_price = listing.price;
        assert!(sender == seller, 1);
        listing.price = price;
        event::emit(ChangePriceEvent<FT> {
            seller,
            nft_id: listing.nft,
            safe_id: listing.safe,
            marketplace: listing.market_id,
            old_price,
            new_price: price
        })
    }

    fun extract_transfer_cap_from_listing<FT>(listing: &mut Listing<FT>): TransferCap {
        option::extract<TransferCap>(&mut listing.transfer_cap)
    }
}