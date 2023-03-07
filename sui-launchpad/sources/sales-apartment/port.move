module sui_launchpad::port {

    use std::vector;

    use sui::clock::{Clock};
    use sui::coin::{Self, Coin};
    use sui::pay::{join_vec};
    use sui::tx_context::TxContext;
    use sui_launchpad::plan::{Self, SalePlan};
    use sui_launchpad::administrate::{Self, Launchpad};
    use sui::tx_context;
    use sui::transfer;
    use sui_launchpad::financial;


    entry fun sale_mint<C, T>(
        launchpad: &mut Launchpad<C>,
        sale_plan: &mut SalePlan<C, T>,
        plan_index: u64,
        mint_amount: u64,
        sig: vector<u8>,
        wallet: vector<Coin<T>>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let coins = vector::pop_back(&mut wallet);
        join_vec(&mut coins, wallet);
        let price = plan::get_plan_price<C, T>(sale_plan, plan_index);
        let total_cost = price * mint_amount;
        // TODO: error unify
        assert!(coin::value(&coins) >= total_cost, 8);
        // settlement first
        let beneficiary = plan::borrow_beneficiary_mut<C, T>(sale_plan);
        financial::settlement(beneficiary, coin::split(&mut coins, total_cost, ctx), ctx);
        plan::check_with_plan<C, T>(sale_plan, plan_index, mint_amount, clock, ctx);
        // TODO: only support offchain whitelist currently
        if (plan::does_whitelist<C, T>(sale_plan, plan_index)) {
            plan::check_whitelist<C, T>(launchpad, sale_plan, plan_index, &sig);
        };
        let nfts = administrate::sale_mint<C>(launchpad, mint_amount, ctx);
        // update numbers in plan
        plan::increase_sale_plan_counter<C, T>(sale_plan, plan_index, mint_amount, ctx);
        let len = vector::length(&nfts);
        let sender = tx_context::sender(ctx);
        let i = 0;
        while (i < len) {
            let nft = vector::pop_back(&mut nfts);
            transfer::transfer(nft, sender);
            i = i + 1;
        };
        vector::destroy_empty(nfts);
        transfer::transfer(coins, sender);

    }

}
