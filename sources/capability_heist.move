/*
    In the first place, this quest requires from you complete the smart contract following provided hints (TODOs)
    After that, you should answer the four questions located in "QUESTIONS AND ANSWERS" section and type your answers
        in the corresponding consts with prefix "USER_ANSWER" in capability_heist module.
*/
module overmind::capability_heist {
    use std::signer;
    // use std::string::{Self, String};
    use aptos_std::aptos_hash;
    use aptos_std::capability;
    use aptos_framework::account::{Self, SignerCapability};
    use std::vector;

    friend overmind::capability_heist_test;

    ////////////
    // ERRORS //
    ////////////

    const ERROR_ACCESS_DENIED: u64 = 0;
    const ERROR_ROBBER_NOT_INITIALIZED: u64 = 1;
    const ERROR_INCORRECT_ANSWER: u64 = 2;

    // Seed for PDA account
    const SEED: vector<u8> = b"CapabilityHeist";

    ///////////////////////////
    // QUESTIONS AND ANSWERS //
    ///////////////////////////

    const ENTER_BANK_QUESTION: vector<u8> = b"What function is used to initialize a capability? The answer should start with a lower-case letter";
    const ENTER_BANK_ANSWER: vector<u8> = x"811d26ef9f4bfd03b9f25f0a8a9fa7a5662460773407778f2d10918037194536091342f3724a9db059287c0d06c6942b66806163964efc0934d7246d1e4a570d";

    const TAKE_HOSTAGE_QUESTION: vector<u8> = b"Can you acquire a capability if the feature is not defined in the module you're calling from? The answer should start with a capital letter (Yes/No)";
    const TAKE_HOSTAGE_ANSWER: vector<u8> = x"eba903d4287aaaed303f48e14fa1e81f3307814be54503d4d51e1c208d55a1a93572f2514d1493b4e9823e059230ba7369e66deb826a751321bbf23b78772c4a";

    const GET_KEYCARD_QUESTION: vector<u8> = b"How many ways are there to obtain a capability? The answer should contain only digits";
    const GET_KEYCARD_ANSWER: vector<u8> = x"564e1971233e098c26d412f2d4e652742355e616fed8ba88fc9750f869aac1c29cb944175c374a7b6769989aa7a4216198ee12f53bf7827850dfe28540587a97";

    const OPEN_VAULT_QUESTION: vector<u8> = b"Can capability be stored in the global storage? The answer should start with a capital letter (Yes/No)";
    const OPEN_VAULT_ANSWER: vector<u8> = x"51d13ec71721d968037b05371474cbba6e0acb3d336909662489d0ff1bf58b028b67b3c43e04ff2aa112529e2b6d78133a4bb2042f9c685dc9802323ebd60e10";

    const ENTER_BANK_USER_ANSWER: vector<u8> = b"create";
    const TAKE_HOSTAGE_USER_ANSWER: vector<u8> = b"Yes";
    const GET_KEYCARD_USER_ANSWER: vector<u8> = b"2";
    const OPEN_VAULT_USER_ANSWER: vector<u8> = b"No";

    /////////////////////////
    // CAPABILITY FEATURES //
    /////////////////////////

    struct EnterBank has drop {}
    struct TakeHostage has drop {}
    struct GetKeycard has drop {}
    struct OpenVault has drop {}

    /*
        Struct representing a player of the game
    */
    struct Robber has key {
        // Capability of a PDA account
        cap: SignerCapability
    }

    /*
        Initializes smart contract by creating a PDA account and capabilities
        @param robber - player of the game
    */
    public entry fun init(robber: &signer) {
        assert_valid_robber(robber);

        let signer_cap: SignerCapability;
        (_, signer_cap) = account::create_resource_account(robber, SEED);

        let robber_struct = Robber {
            cap: signer_cap,
        };

        move_to(robber, robber_struct);
    }

    /*
        Verifies answer for the first question and delegates EnterBank capability to the robber
        @param robber - player of the game
        @param answer - answer to the ENTER_BANK_QUESTION question
    */
    public entry fun enter_bank(robber: &signer) acquires Robber {
        assert_robber_initialized(robber);
        let robber_resource = move_from<Robber>(signer::address_of(robber));

        assert_answer_is_correct(ENTER_BANK_USER_ANSWER, ENTER_BANK_ANSWER);
        let enterBank = new_enter_bank();
        delegate_capability(robber, &enterBank);
        move_to<Robber>(robber, robber_resource);
    }

    /*
        Verifies answer for the second question and delegates TakeHostage capability to the robber
        @param robber - player of the game
        @param answer - answer to the TAKE_HOSTAGE_QUESTION question
    */
    public entry fun take_hostage(robber: &signer) acquires Robber {
        assert_robber_initialized(robber);
        let robber_resource = move_from<Robber>(signer::address_of(robber));

        capability::acquire(robber, &new_enter_bank());

        assert_answer_is_correct(TAKE_HOSTAGE_USER_ANSWER, TAKE_HOSTAGE_ANSWER);

        let takeHostage = new_take_hostage();
        delegate_capability(robber, &takeHostage);
        move_to<Robber>(robber, robber_resource);
    }

    /*
        Verifies answer for the third question and delegates GetKeycard capability to the robber
        @param robber - player of the game
        @param answer - answer to the GET_KEYCARD_QUESTION question
    */
    public entry fun get_keycard(robber: &signer) acquires Robber {
        assert_robber_initialized(robber);
        let robber_resource = move_from<Robber>(signer::address_of(robber));

        capability::acquire(robber, &new_enter_bank());
        capability::acquire(robber, &new_take_hostage());
        assert_answer_is_correct(GET_KEYCARD_USER_ANSWER, GET_KEYCARD_ANSWER);

        let getKeyCard = new_get_keycard();
        delegate_capability(robber, &getKeyCard);
        move_to<Robber>(robber, robber_resource);
    }

    /*
        Verifies answer for the fourth question and delegates OpenVault capability to the robber
        @param robber - player of the game
        @param answer - answer to the OPEN_VAULT_QUESTION question
    */
    public entry fun open_vault(robber: &signer) acquires Robber {
        assert_robber_initialized(robber);
        let robber_resource = move_from<Robber>(signer::address_of(robber));

        capability::delegate(
            capability::acquire(robber, &new_enter_bank()),
            &new_enter_bank(),
            robber
        );
        capability::delegate(
            capability::acquire(robber, &new_take_hostage()),
            &new_take_hostage(),
            robber
        );
        capability::delegate(
            capability::acquire(robber, &new_get_keycard()),
            &new_get_keycard(),
            robber
        );
        assert_answer_is_correct(OPEN_VAULT_USER_ANSWER, OPEN_VAULT_ANSWER);

        let openVault = new_open_vault();
        delegate_capability(robber, &openVault);
        move_to<Robber>(robber, robber_resource);
    }

    /*
        Gives the player provided capability
        @param robber - player of the game
        @param feature - capability feature to be given to the player
    */
    public fun delegate_capability<Feature>(
        robber: &signer,
        feature: &Feature
    ) {
        capability::create(robber, feature);
        capability::acquire(robber, feature);
    }

    /*
    Gets user's answers and creates a hash out of it
    @returns - SHA3_512 hash of user's answers
    */
    public fun get_flag(): vector<u8> {
        let answers_vector = &mut vector::empty<u8>();

        let enter_bank_answer = ENTER_BANK_USER_ANSWER;
        let take_hostage_answer = TAKE_HOSTAGE_USER_ANSWER;
        let get_keycard_answer = GET_KEYCARD_USER_ANSWER;
        let open_vault_answer = OPEN_VAULT_USER_ANSWER;

        let i: u64 = 0;

        // add ENTER_BANK_USER_ANSWER to answers_vector
        let len = vector::length(&enter_bank_answer);
        while (i < len) {
            let answer = vector::borrow(&enter_bank_answer, i);
            vector::push_back(answers_vector, *answer);
            i = i + 1;
        };

        i = 0;

        // add TAKE_HOSTAGE_USER_ANSWER to answers_vector
        len = vector::length(&take_hostage_answer);
        while (i < len) {
            let answer = vector::borrow(&take_hostage_answer, i);
            vector::push_back(answers_vector, *answer);
            i = i + 1;
        };

        i = 0;

        // add GET_KEYCARD_USER_ANSWER to answers_vector
        len = vector::length(&get_keycard_answer);
        while (i < len) {
            let answer = vector::borrow(&get_keycard_answer, i);
            vector::push_back(answers_vector, *answer);
            i = i + 1;
        };

        i = 0;

        // add OPEN_VAULT_USER_ANSWER to answers_vector
        len = vector::length(&open_vault_answer);
        while (i < len) {
            let answer = vector::borrow(&open_vault_answer, i);
            vector::push_back(answers_vector, *answer);
            i = i + 1;
        };

        let hash = aptos_hash::sha3_512(copy_vec(answers_vector));
        hash
    }

    public fun copy_vec(orig: &vector<u8>): vector<u8> {
        let len = vector::length(orig);
        let new_vec = vector::empty<u8>();
        let i = 0;

        while (i < len) {
            let val = *vector::borrow(orig, i);
            vector::push_back(&mut new_vec, val);
            i = i + 1;
        };

        new_vec
    }


    /*
        Checks if Robber resource exists under the provided address
        @param robber_address - address of the player
        @returns - true if it exists, otherwise false
    */
    public(friend) fun check_robber_exists(robber_address: address): bool {
        let exists = exists<Robber>(robber_address);
        exists
    }

    /*
        EnterBank constructor
    */
    public(friend) fun new_enter_bank(): EnterBank {
        let enterBank = EnterBank {};
        enterBank
    }

    /*
        TakeHostage constructor
    */
    public(friend) fun new_take_hostage(): TakeHostage {
        let takeHostage = TakeHostage {};
        takeHostage
    }

    /*
        GetKeycard constructor
    */
    public(friend) fun new_get_keycard(): GetKeycard {
        let keyCard = GetKeycard {};
        return keyCard
    }

    /*
        OpenVault constructor
    */
    public(friend) fun new_open_vault(): OpenVault {
        let openVault = OpenVault {};
        return openVault
    }

    /////////////
    // ASSERTS //
    /////////////

    inline fun assert_valid_robber(robber: &signer) {
        assert!(signer::address_of(robber) == @0x1234, ERROR_ACCESS_DENIED);
    }

    inline fun assert_robber_initialized(robber: &signer) {
        assert!(exists<Robber>(signer::address_of(robber)), ERROR_ROBBER_NOT_INITIALIZED);
    }

    inline fun assert_answer_is_correct(expected_answer: vector<u8>, actual_answer: vector<u8>) {
        assert!(actual_answer == aptos_hash::sha3_512(expected_answer), ERROR_INCORRECT_ANSWER);
    }
}
