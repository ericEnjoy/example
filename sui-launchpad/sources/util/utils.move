/// Utility functions
module sui_launchpad::utils {
    use std::bcs;
    use std::hash;
    use std::ascii;
    use std::vector;
    use std::type_name;
    use std::bit_vector::{Self, BitVector};
    use std::string::{Self, String, sub_string};

    use sui::vec_map::{Self, VecMap};
    use sui::bcs::{new, peel_u64};

    use nft_protocol::err;

    /// First generic `T` is any type, second generic is `Witness`.
    /// `Witness` is a type always in form "struct Witness has drop {}"
    ///
    /// In this method, we check that `T` is exported by the same _module_.
    /// That is both package ID, package name and module name must match.
    /// Additionally, with accordance to the convention above, the second
    /// generic `Witness` must be named `Witness` as a type.
    ///
    /// # Example
    /// It's useful to assert that a one-time-witness is exported by the same
    /// contract as `Witness`.
    /// That's because one-time-witness is often used as a convention for
    /// initiating e.g. a collection name.
    /// However, it cannot be instantiated outside of the `init` function.
    /// Therefore, the collection contract can export `Witness` which serves as
    /// an auth token at a later stage.
    public fun assert_same_module_as_witness<T, Witness>() {
        let (package_a, module_a, _) = get_package_module_type<T>();
        let (package_b, module_b, witness_type) = get_package_module_type<Witness>();

        assert!(package_a == package_b, err::witness_source_mismatch());
        assert!(module_a == module_b, err::witness_source_mismatch());
        assert!(witness_type == string::utf8(b"Witness"), err::must_be_witness());
    }

    public fun get_package_module_type<T>(): (String, String, String) {
        let delimiter = string::utf8(b"::");

        let t = string::utf8(ascii::into_bytes(
            type_name::into_string(type_name::get<T>())
        ));

        // TBD: this can probably be hard-coded as all hex addrs are 32 bytes
        let package_delimiter_index = string::index_of(&t, &delimiter);
        let package_addr = sub_string(&t, 0, string::index_of(&t, &delimiter));

        let tail = sub_string(&t, package_delimiter_index + 2, string::length(&t));

        let module_delimiter_index = string::index_of(&tail, &delimiter);
        let module_name = sub_string(&tail, 0, module_delimiter_index);

        let type_name = sub_string(&tail, module_delimiter_index + 2, string::length(&tail));

        (package_addr, module_name, type_name)
    }

    public fun from_vec_to_map<K: copy + drop, V: drop>(
        keys: vector<K>,
        values: vector<V>,
    ): VecMap<K, V> {
        let i = 0;
        let n = vector::length(&keys);
        let map = vec_map::empty<K, V>();

        while (i < n) {
            let key = vector::pop_back(&mut keys);
            let value = vector::pop_back(&mut values);

            vec_map::insert(
                &mut map,
                key,
                value,
            );

            i = i + 1;
        };

        map
    }

    public fun pseudo_random(add: address, remaining: u64): u64 {
        // add some more disturbance here
        let x = bcs::to_bytes<address>(&add);
        let y = bcs::to_bytes<u64>(&remaining);
        vector::append(&mut x,y);
        let tmp = hash::sha2_256(x);

        let data = vector<u8>[];
        let i =24;
        while (i < 32) {
            let x =vector::borrow(&tmp,i);
            vector::append(&mut data,vector<u8>[*x]);
            i= i+1;
        };
        assert!(remaining > 0, 999);

        let bcs_value = new(data);
        let random = peel_u64(&mut bcs_value) % remaining + 1;
        if (random == 0 ) {
            random = 1;
        };
        random
    }

    public fun create_bit_mask(nfts: u64): vector<BitVector> {
        let full_buckets = nfts / 1024;
        let remaining = nfts - full_buckets * 1024;
        if (nfts < 1024) {
            full_buckets = 0;
            remaining = nfts;
        };
        let v1 = vector::empty();
        while (full_buckets > 0) {
            let new = bit_vector::new(1023);
            vector::push_back(&mut v1, new);
            full_buckets=full_buckets-1;
        };
        vector::push_back(&mut v1,bit_vector::new(remaining));
        v1
    }
}
