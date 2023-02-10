module Souffl3::marketplace {

    use std::fixed_point32;

    use sui::object::{Self,  UID};
    use sui::tx_context::{TxContext};

    use sui::transfer::share_object;

    const BPS: u64 = 10000;

    // only support sui::Sui now
    struct MarketPlace has key, store {
        id: UID,
        beneficiary: address,
        fee_bps: u64,
        // market fee aggregate address for distributing to multi beneficiaries
    }

    public entry fun create_market(beneficiary: address, fee_bps: u64, ctx: &mut TxContext) {
        let market = MarketPlace {
            id: object::new(ctx),
            beneficiary,
            fee_bps
        };
        share_object(market);
    }

    public fun calc_market_fee(market: &MarketPlace, amount: u64): u64 {
        let market_fee_rate = fixed_point32::create_from_rational(
            market.fee_bps,
            BPS
        );

        fixed_point32::multiply_u64(
            amount,
            market_fee_rate
        )
    }

    public fun get_beneficiary(marketplace: &MarketPlace): address {
        marketplace.beneficiary
    }
}