module sui_launchpad::record {

    use sui::table::{Self, Table};
    use sui::tx_context::TxContext;

    friend sui_launchpad::plan;

    struct SaleRecord has store {
        record: Table<address, u64>
    }

    public fun create_sale_record(ctx: &mut TxContext): SaleRecord {
        SaleRecord {
            record: table::new<address, u64>(ctx)
        }
    }

    public(friend) fun get_sale_number(
        sale_record: &SaleRecord,
        addr: address
    ): u64 {
        assert!(table::contains(&sale_record.record, addr), 9);
        *table::borrow(&sale_record.record, addr)
    }

    public fun check(
        sale_record: &SaleRecord,
        mint_amount: u64,
        max_amount: u64,
        addr: address
    ) {
        let record = &sale_record.record;
        if (table::contains(record, addr)) {
            let count = *table::borrow(record, addr);
            // TODO: error unify
            assert!(max_amount >=  (count + mint_amount), 4)
        }
    }

    public(friend) fun increase_record(
        record: &mut SaleRecord,
        mint_amount: u64,
        addr: address
    ) {
        // TODO: error unify
        assert!(table::contains(&record.record, addr), 8);
        let addr_count = table::borrow_mut(&mut record.record, addr);
        *addr_count = *addr_count + mint_amount;
    }

}
