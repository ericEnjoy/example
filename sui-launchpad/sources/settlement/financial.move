module sui_launchpad::financial {

    use std::option::{Self, Option};

    use sui_launchpad::shared_account::{SharedAccount};
    use sui_launchpad::locked_account::{LockedAccount};
    use sui::tx_context::TxContext;
    use sui::coin::Coin;
    use sui_launchpad::shared_account;
    use sui::tx_context;
    use sui::transfer;

    struct Beneficiary has store {
        account_type: u8,
        shared: Option<SharedAccount>,
        locked: Option<LockedAccount>
    }

    public fun create_beneficiary_shared(
        account_type: u8,
        accounts: vector<address>,
        share_nums: vector<u64>
    ): Beneficiary {
        let shared_ = shared_account::create_shared_account(accounts, share_nums);

        Beneficiary {
            account_type,
            shared: option::some(shared_),
            locked: option::none<LockedAccount>()
        }
    }

    // TODO: deal with locked account
    public fun create_beneficiary_locked(
        account_type: u8,
    ): Beneficiary {

        Beneficiary {
            account_type,
            shared: option::none<SharedAccount>(),
            locked: option::none<LockedAccount>()
        }

    }

    public fun settlement<T>(
        beneficiary: &mut Beneficiary,
        coins: Coin<T>,
        ctx: &mut TxContext
    ) {
        if (beneficiary.account_type == 1) {
            let shared_account = option::borrow(&beneficiary.shared);
            shared_account::disperse(shared_account, coins, ctx);
        } else {
            // TODO: deal with locked account type
            transfer::transfer(coins, tx_context::sender(ctx));
        };
    }
}
