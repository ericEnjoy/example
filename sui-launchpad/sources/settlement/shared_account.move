module sui_launchpad::shared_account {

    use sui::transfer;
    use sui::coin::{Self, Coin};
    use std::vector;
    use sui::tx_context::TxContext;

    friend sui_launchpad::financial;

    struct SharedAccount has store {
        shares: vector<Share>,
        total_shares: u64
    }

    struct Share has store {
        account: address,
        share: u64
    }

    public(friend) fun create_shared_account(
        accounts: vector<address>,
        nums: vector<u64>
    ): SharedAccount {
        let total_shares = 0;
        let len = vector::length(&accounts);
        let shares = vector::empty<Share>();
        let i = 0;
        while (i < len) {
            let num = vector::pop_back(&mut nums);
            let addr = vector::pop_back(&mut accounts);
            let share = Share {
                account: addr,
                share: num
            };
            vector::push_back(&mut shares, share);
            total_shares = total_shares + num;
            i = i + 1;
        };
        SharedAccount {
            shares,
            total_shares
        }
    }

    public fun disperse<T>(
        shared_account: &SharedAccount,
        coins: Coin<T>,
        ctx: &mut TxContext
    ) {
        let coin_amount = coin::value(&coins);
        let balance = coin::into_balance(coins);
        let len = vector::length(&shared_account.shares);
        let total_share = shared_account.total_shares;
        let i = 0;
        while(i < (len - 1)) {
            let share = vector::borrow(&shared_account.shares, i);
            let numerator = share.share;
            let coin_amount = coin_amount * numerator / total_share;
            let disperse_coin = coin::take(&mut balance, coin_amount, ctx);
            transfer::transfer(disperse_coin, share.account);
            i = i + 1;
        };
        let remaining_coin = coin::from_balance(balance, ctx);
        transfer::transfer(remaining_coin, vector::borrow(&shared_account.shares, i).account);
    }
}
