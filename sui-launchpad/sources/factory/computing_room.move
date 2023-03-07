module sui_launchpad::computing_room {

    use std::vector;
    use std::bit_vector;
    use std::option::{Self, Option};
    use sui_launchpad::utils;
    use std::bit_vector::BitVector;

    friend sui_launchpad::administrate;

    struct Maze has store, drop {
        does_sequential: bool,
        bits: Option<vector<BitVector>>
    }

    public fun create_maze(does_sequential: bool, max: u64): Maze {
        let bits = option::none<vector<BitVector>>();
        if (!does_sequential) {
            let bit_vec = utils::create_bit_mask(max);
            option::fill(&mut bits, bit_vec);
        };
        Maze {
            does_sequential,
            bits
        }
    }

    public fun get_mint_index(maze: &mut Maze, remaining: u64, index: u64, receiver_addr: address): u64 {
        if (maze.does_sequential) {
            index
        } else {
            get_random_index(maze, remaining, receiver_addr)
        }
    }

    fun get_random_index(maze: &mut Maze, remaining: u64, receiver_addr: address): u64 {

        let random_index = utils::pseudo_random(receiver_addr, remaining);

        let required_position= 0;
        let bucket = 0;
        let pos= 0;
        let new = vector::empty();
        let bit_vec = option::borrow_mut(&mut maze.bits);

        while (required_position < random_index) {
            let bitvector=*vector::borrow_mut(bit_vec, bucket);
            let i =0;
            while (i < bit_vector::length(&bitvector)) {
                if (!bit_vector::is_index_set(&bitvector, i)) {
                    required_position = required_position + 1;
                };
                if (required_position == random_index) {
                    bit_vector::set(&mut bitvector, i);
                    vector::push_back(&mut new, bitvector);
                    break
                };
                pos = pos + 1;
                i = i + 1;
            };
            vector::push_back(&mut new, bitvector);
            bucket=bucket + 1
        };

        while (bucket < vector::length(bit_vec)) {
            let bitvector=*vector::borrow_mut(bit_vec, bucket);
            vector::push_back(&mut new, bitvector);
            bucket=bucket+1;
        };

        *bit_vec = new;
        pos
    }
}
