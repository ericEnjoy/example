module sui_launchpad::workshop {

    use sui_launchpad::warehouse::NFTContent;
    use nft_protocol::nft::{Self, Nft};
    use sui_launchpad::warehouse;
    use sui::tx_context::TxContext;
    use nft_protocol::mint_cap::{UnregulatedMintCap, RegulatedMintCap};
    use nft_protocol::display;

    friend sui_launchpad::administrate;

    public(friend) fun mint_token_with_unregulated<C>(
        content: &NFTContent,
        mint_cap: &UnregulatedMintCap<C>,
        ctx: &mut TxContext
    ): Nft<C> {
        // distingush mint cap type
        let token = nft::from_unregulated<C>(
            mint_cap,
            warehouse::get_nft_name(content),
            warehouse::get_nft_url(content),
            ctx
        );
        let (symbol_flag, symbol) = warehouse::get_nft_symbol(content);
        if (symbol_flag) {
            let symbol_domain = display::new_symbol_domain(symbol);
            nft::add_domain_with_unregulated(mint_cap, &mut token, symbol_domain, ctx);
        };
        let (attribute_keys_flag, attribute_keys) = warehouse::get_nft_attributes_keys(content);
        let (attribute_values_flag, attribute_values) = warehouse::get_nft_attributes_values(content);
        if (attribute_keys_flag && attribute_values_flag) {
            let attribute_domain = display::new_attributes_domain_from_vec(attribute_keys, attribute_values);
            nft::add_domain_with_unregulated(mint_cap, &mut token, attribute_domain, ctx);
        };

        token
    }

    public(friend) fun mint_token_with_regulated<C>(
        content: &NFTContent,
        mint_cap: &mut RegulatedMintCap<C>,
        ctx: &mut TxContext
    ): Nft<C> {
        // distingush mint cap type
        let token = nft::from_regulated<C>(
            mint_cap,
            warehouse::get_nft_name(content),
            warehouse::get_nft_url(content),
            ctx
        );
        let (symbol_flag, symbol) = warehouse::get_nft_symbol(content);
        if (symbol_flag) {
            let symbol_domain = display::new_symbol_domain(symbol);
            nft::add_domain_with_regulated(mint_cap, &mut token, symbol_domain, ctx);
        };
        let (attribute_keys_flag, attribute_keys) = warehouse::get_nft_attributes_keys(content);
        let (attribute_values_flag, attribute_values) = warehouse::get_nft_attributes_values(content);
        if (attribute_keys_flag && attribute_values_flag) {
            let attribute_domain = display::new_attributes_domain_from_vec(attribute_keys, attribute_values);
            nft::add_domain_with_regulated(mint_cap, &mut token, attribute_domain, ctx);
        };
        token
    }
}