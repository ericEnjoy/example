module sui_launchpad::plan {

    use std::vector;
    use std::string::String;
    use std::option::{Self, Option};

    use sui::object::{Self, UID};
    use sui::bcs::{to_bytes};
    use sui::clock::{Clock, timestamp_ms};
    use sui::tx_context::TxContext;
    use sui::transfer::share_object;
    use sui_launchpad::record::{Self, create_sale_record, SaleRecord};
    use sui::tx_context;
    use sui_launchpad::financial::Beneficiary;
    use sui_launchpad::financial;
    use sui_launchpad::utils;
    use sui_launchpad::whitelist::Whitelist;
    use sui_launchpad::whitelist;
    use sui_launchpad::administrate::{Launchpad, AdminCap};
    use sui_launchpad::permission::{Self, Permission};
    use sui_launchpad::utils::assert_same_module_as_witness;

    struct SalePlan<phantom C, phantom T> has key, store {
        id: UID,
        plans: vector<Plan>,
        beneficiary: Beneficiary
    }

    struct Plan has store {
        plan_name: String,
        price: u64,
        start_at: u64,
        end_at: u64,
        does_whitelist: bool,
        whitelist: Option<Whitelist>,
        record: SaleRecord,
        max_amount_this_plan: u64,
        max_mint_amount_per_address: u64,
        already_mint_amount_this_plan: u64,
    }

    public fun create_sale_plan<C, T>(
        _admin_cap: &AdminCap<C>,
        account_type: u8,
        beneficiaries: vector<address>,
        share_nums: vector<u64>,
        ctx: &mut TxContext
    ) {
        let beneficiary = financial::create_beneficiary_shared(account_type, beneficiaries, share_nums);
        let sale_plan = SalePlan<C, T> {
            id: object::new(ctx),
            plans: vector::empty<Plan>(),
            beneficiary
        };
        share_object(sale_plan);
    }

    public fun add_plan<C, T>(
        _admin_cap: &AdminCap<C>,
        sale_plan: &mut SalePlan<C, T>,
        plan_name: String,
        price: u64,
        start_at: u64,
        end_at: u64,
        does_whitelist: bool,
        whitelist_type: u8,
        max_amount_this_plan: u64,
        max_mint_amount_per_address: u64,
        ctx: &mut TxContext
    ) {
        // TODO: whether to judge the number of plans
        let whitelist_ = option::none<Whitelist>();
        if(does_whitelist) {
            let wl = whitelist::create_whitelist(whitelist_type);
            option::fill(&mut whitelist_, wl);
        };
        let plan = Plan {
            plan_name,
            price,
            start_at,
            end_at,
            does_whitelist,
            whitelist: whitelist_,
            record: create_sale_record(ctx),
            max_amount_this_plan,
            max_mint_amount_per_address,
            already_mint_amount_this_plan: 0u64
        };
        vector::push_back(&mut sale_plan.plans, plan);
    }

    public fun add_pubkey_into_whitelist_by_admin<C, T>(
        permission: &Permission,
        sale_plan: &mut SalePlan<C, T>,
        plan_index: u64,
        pub_key: address,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        permission::check_permission(permission, sender);
        let plan = vector::borrow_mut(&mut sale_plan.plans, plan_index);
        if (!plan.does_whitelist) {
            // TODO: error unify
            abort 20
        };
        // TODO: error unify
        assert!(option::is_some(&plan.whitelist), 22);
        let whitelist_offchain = option::borrow_mut(&mut plan.whitelist);
        whitelist::add_pubkey_into_offchain_whitelist(whitelist_offchain, pub_key);

    }

    public fun add_pubkey_into_whitelist<C, T>(
        _admin_cap: &AdminCap<C>,
        sale_plan: &mut SalePlan<C, T>,
        plan_index: u64,
        pub_key: address
    ) {
        let plan = vector::borrow_mut(&mut sale_plan.plans, plan_index);
        if (!plan.does_whitelist) {
            // TODO: error unify
            abort 20
        };
        let whitelist_offchain = option::borrow_mut(&mut plan.whitelist);
        whitelist::add_pubkey_into_offchain_whitelist(whitelist_offchain, pub_key);
    }

    public fun modify_plan_with_cap<C>(
        _admin_cap: &AdminCap<C>
    ) {

    }

    public fun modify_plan_by_admin<C>() {

    }

    public fun increase_sale_plan_counter<C, T>(
        sale_plan: &mut SalePlan<C, T>,
        plan_index: u64,
        mint_amount: u64,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let plan = vector::borrow_mut(&mut sale_plan.plans, plan_index);

        plan.already_mint_amount_this_plan = plan.already_mint_amount_this_plan + mint_amount;
        // increase sender record
        record::increase_record(&mut plan.record, mint_amount, sender);
    }

    public fun check_with_plan<C, T>(
        sale_plan: &SalePlan<C, T>,
        plan_index: u64,
        mint_amount: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let plan = vector::borrow(&sale_plan.plans, plan_index);
        // TODO: error unify
        assert!(plan.already_mint_amount_this_plan >= (plan.max_amount_this_plan + mint_amount), 2);
        record::check(&plan.record, mint_amount, plan.max_mint_amount_per_address, sender);
        let time_now_sec = timestamp_ms(clock) / 1000;
        // TODO: error unify
        assert!(plan.start_at <= time_now_sec, 6);
        assert!(plan.end_at > time_now_sec, 7);
    }

    public fun does_whitelist<C, T>(
        sale_plan: &SalePlan<C, T>,
        plan_index: u64,
    ): bool {
        vector::borrow(&sale_plan.plans, plan_index).does_whitelist
    }

    public fun get_plan_price<C, T>(
        sale_plan: &SalePlan<C, T>,
        plan_index: u64
    ): u64 {
        vector::borrow(&sale_plan.plans, plan_index).price
    }

    public fun borrow_beneficiary_mut<C, T>(
        sale_plan: &mut SalePlan<C, T>,
    ): &mut Beneficiary {
        &mut sale_plan.beneficiary
    }

    public fun check_whitelist<C, T>(
        launchpad: &Launchpad<C>,
        sale_plan: &SalePlan<C, T>,
        plan_index: u64,
        signature: &vector<u8>
    ) {
        let plan = vector::borrow(&sale_plan.plans, plan_index);
        if (plan.does_whitelist) {
            let wl = option::borrow(&plan.whitelist);
            let wl_type = whitelist::get_whitelist_type(wl);
            if (wl_type == 2) {
                // construct msg
                // bcs(launchpad) + bcs(sale_plan) + bcs(plan_index)
                let msg_vec = to_bytes(launchpad);
                let sale_plan = to_bytes(sale_plan);
                let plan_index_vec = to_bytes(&plan_index);
                vector::append(&mut msg_vec, sale_plan);
                vector::append(&mut msg_vec, plan_index_vec);
                whitelist::check_offchain<C, T>(wl, &msg_vec, signature);
            }
        };
    }


}
