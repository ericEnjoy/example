module sui_launchpad::whitelist {

    use std::option::{Self, Option};
    use sui::bcs::{to_bytes};
    use sui::table::{Table};
    use sui::ed25519::{ed25519_verify};

    friend sui_launchpad::plan;

    struct Whitelist has store {
        whitelist_type: u8,
        whitelist_on_chain: Option<WhitelistOnChain>,
        whitelist_off_chain: Option<WhitelistOffChain>
    }

    struct WhitelistOnChain has store {
        record: Table<address, u64>
    }

    struct WhitelistOffChain has store {
        public_key: address
    }

    public fun create_whitelist(
        whitelist_type: u8
    ): Whitelist {
        // TODO: error unify
        assert!(whitelist_type < 3, 13);
        Whitelist {
            whitelist_type,
            whitelist_on_chain: option::none<WhitelistOnChain>(),
            whitelist_off_chain: option::none<WhitelistOffChain>()
        }
    }

    public fun check_onchain(
        _whitelist: & WhitelistOnChain,
        _addr: address
    ): bool {
        false
    }

    public fun check_offchain<C, T>(
        wl: &Whitelist,
        msg: &vector<u8>,
        signature: &vector<u8>,
    ) {
        // TODO: erorr unify
        if (option::is_some(&wl.whitelist_off_chain)) {
            // TODO: error unify
            abort 20
        };
        let wl_offchain = option::borrow(&wl.whitelist_off_chain);
        assert!(
            ed25519_verify(signature, &to_bytes(&wl_offchain.public_key), msg),
            12
        );
    }

    public fun add_whitelist_onchain(
        _whitelist: &mut WhitelistOnChain,
        _addresses: vector<address>
    ) {

    }

    public(friend) fun add_pubkey_into_offchain_whitelist(
        wl: &mut Whitelist,
        public_key: address
    ) {
        // TODO: error unify
        assert!(wl.whitelist_type == 2, 23);
        let wl_offchain = option::borrow_mut(&mut wl.whitelist_off_chain);
        wl_offchain.public_key = public_key;
    }

    public fun turn_off_whitelist(
        _whitelist: &mut WhitelistOnChain,
        _addr: address
    ) {

    }

    public fun turn_on_whitelist(
        _whitelist: &mut WhitelistOnChain,
        _addr: address
    ) {

    }

    public fun get_whitelist_type(
        whitelist: &Whitelist
    ): u8 {
        whitelist.whitelist_type
    }

}
