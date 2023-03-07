module sui_launchpad::permission {

    use sui::table::{Self, Table};
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::transfer::share_object;
    use sui::tx_context;


    struct Permission has key, store {
        id: UID,
        admin: address,
        address: Table<address, bool>
    }

    fun init(ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        share_object(Permission {
            id: object::new(ctx),
            admin: sender,
            address: table::new<address, bool>(ctx)
        });
    }

    entry fun add_address(
        permission: &mut Permission,
        addr: address,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        // TODO: error unify
        assert!(sender == permission.admin, 11);
        if (!table::contains(&permission.address, addr)) {
            table::add(&mut permission.address, addr, true);
        }
    }

    public fun check_permission(
        permission: &Permission,
        addr: address,
    ) {
        // TODO: error unify
        assert!(table::contains(&permission.address, addr), 10);
    }



}
