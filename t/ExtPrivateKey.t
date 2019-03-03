use strict;
use warnings;

use Test::More;
use Try::Tiny;

use Bitcoin::Crypto::Base58 qw(encode_base58check);
BEGIN { use_ok('Bitcoin::Crypto::ExtPrivateKey') };

my @test_data = (
    {
        mnemonic => "crisp curve describe escape consider hip toilet fan range pen sweet plunge mirror brush raise",
        seed => "92add1b3e9dc4b160db53dac1178f5e4055c23a3007abb5394ea74d27cca601270c55eab5d7052b36694efa72aa0dca65505ac72edc8aa9b94021e749b000a0a",
        key => "xprv9s21ZrQH143K3nYJyWSWYLJZ2rvydAFU4dRaLXV9Krqvv8b9t4JzjX73ZunqKY67iWdxUCyvPQ9t5FX5SKi3LosisYovFqCCQPgbE9Ey5pA",
        lang => "en",
        basic => "L3a57KGgirnCw4pRbg5kCeeLaB2YCiGKY3P4E4pYGgc9PgmhHHa3",
    },
    {
        mnemonic => "castle illegal state cupboard pass creek critic impact business attract group flavor",
        seed => "8201b761f2dcadc7f75ebb1fed46033fb3b80aa939e078069c441572bbf46557f27bf48807f3c522d37feb5a4f780402829b4858ecceed396cab7efbb6ed895c",
        key => "xprv9s21ZrQH143K2Xk64TsTEGsitSekVT8K4MmgkZSMhoWuePKA2abZoMdCktDnr8LakTnVXBwRAK2EFPzPYuaEQSoJZhfdSMkS8zbk28VjskZ",
        lang => "en",
        basic => "L1CZbrUKVDMe7iBv3pVH2X5gpXj6Er4Tyec1Ra7tjJVwAFR5ZkWg",
    },
    {
        mnemonic => "require lens exercise tank bind shadow detail pelican half same mountain breeze dinosaur secret army omit weasel myth luxury swarm company wrestle wide curious",
        seed => "fe40c2dc3fc98cbac2d31c6b9ba8be1187060ec5205f12f5aefb239c4b2093d0389af9e9651e993e15ba33b85153fb4500eee75da9c1891c5a5c28078e4f5efe",
        key => "xprv9s21ZrQH143K371wiGee9MD2rzZsu6VoqQ4ieVRmnmWc3FRCn8re7qV34whgGwFK87xELbLCxU5JcJCzzJis1YdNSoTHSUCgeHCAsTjkHA2",
        lang => "en",
        basic => "KxD95rySyjzCxW2YMm3UE9eg8Yxs9YnHyqqVekjAoMU3Xacvq6C9",
    },
    {
        mnemonic => "annual burden skirt okay simple now wave hard spot exact merit original",
        passphrase => "hello",
        seed => "f756c680f02f4f0362f7b1added7de5d318b4d5e5a9c53333bc711bdbd87a6d44872b2a51d48b1d596969c37a4021aeec706b309aaffcf12445999bcf50ac8cc",
        key => "xprv9s21ZrQH143K4NSZD9RXzfnkk4jwoBCBSJnTbBNwLLwhd2n4yjYDBvWLGTqgqxuUr3WpkvXh7H4gUyduRVbww17F9edVPpjzHb4qscAs3Tb",
        lang => "en",
        basic => "L1GoBvbdsmfnRyf36XB77JPU6M53iJD85pEq4ksxaeGkp1Mwccuf",
    },
    {
        mnemonic => "daughter face ability round midnight sibling rifle gorilla spin busy legend wear",
        passphrase => "zażółć gęślą jaźń",
        seed => "bb500760edebad71314d4151beac38a7acc1983346eab3d038c32f6e0c518a77f6e9835db1d5bdeaa4b8c8b3ae72b743a5d7625bd8c07cca5774be5024e0d6df",
        key => "xprv9s21ZrQH143K2mGZK6FJ641ZXQPVGzcg27LLrLEV1FGtt3uXWk5f3jSu41WMvyZQd8qPeKdH96iY65DZ5r3TGCmswaR6hcrx8Bhbeor5yqW",
        lang => "en",
        basic => "KxPSc1dT6ZKthyDVTah376AQMNJ7KGY3vAAjzA5xXWsQu2mTmUEh",
    },
    {
        mnemonic => "daughter face ability round midnight sibling rifle gorilla spin busy legend wear",
        passphrase => "a quick brown fox jumped over a lazy dog",
        seed => "1949f598e7acf85058dcd7f3c3d67e6907a6c1f7c694c74717a70a5d6e1f3a03330f9fba38e2ec485241cfaade87eb7527ab128538199aa3ff23b05282c9c628",
        key => "xprv9s21ZrQH143K2e4JGe881wYFpdeNRGwrqpNs8pMuUMfasNU88AKRsM7FjqJ53gHm3zQHGXrUkisLih2bDaoU3xmUGC91Ps3JrbUpdQfeQ44",
        lang => "en",
        basic => "Kx8NSKQ4EqwzGDjQMEyoNAH72DrL7NrHtSfG2FLcNeyY1o1gXa2w",
    },
    {
        mnemonic => "そつう　れきだい　ほんやく　わかす　りくつ　ばいか　ろせん　やちん　そつう　れきだい　ほんやく　わかめ",
        passphrase => "㍍ガバヴァぱばぐゞちぢ十人十色",
        seed => "aee025cbe6ca256862f889e48110a6a382365142f7d16f2b9545285b3af64e542143a577e9c144e101a6bdca18f8d97ec3366ebf5b088b1c1af9bc31346e60d9",
        key => "xprv9s21ZrQH143K3ra1D6uGQyST9UqtUscH99GK8MBh5RrgPkrQo83QG4o6H2YktwSKvoZRVXDQZQrSyCDpHdA2j8i3PW5M9LkauaaTKwym1Wf",
        basic => "L2qjBPXGZfsjMPueZkv2GuqqwRFpLpDz1Jhn7z6rgoR4zYTNqiQy",
    },
    {
        mnemonic => "われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　われる　らいう",
        passphrase => "㍍ガバヴァぱばぐゞちぢ十人十色",
        seed => "a44ba7054ac2f9226929d56505a51e13acdaa8a9097923ca07ea465c4c7e294c038f3f4e7e4b373726ba0057191aced6e48ac8d183f3a11569c426f0de414623",
        key => "xprv9s21ZrQH143K3XTGpC53cWswvhg6GVQ1dE1yty6F9VhBcE7rnXmStuKwtaZNXRxw5N7tsh1REyAxun1S5BCYvhD5pNwxWUMMZaHwjTmXFdb",
        basic => "L4yV63y42pbH68cJJu6wfriKdVgtTTJUm6cxJUQu4Mbsb9XEM2L4",
    },
    {
        mnemonic => "くのう　てぬぐい　そんかい　すろっと　ちきゅう　ほあん　とさか　はくしゅ　ひびく　みえる　そざい　てんすう　たんぴん　くしょう　すいようび　みけん　きさらぎ　げざん　ふくざつ　あつかう　はやい　くろう　おやゆび　こすう",
        passphrase => "㍍ガバヴァぱばぐゞちぢ十人十色",
        seed => "32e78dce2aff5db25aa7a4a32b493b5d10b4089923f3320c8b287a77e512455443298351beb3f7eb2390c4662a2e566eec5217e1a37467af43b46668d515e41b",
        key => "xprv9s21ZrQH143K2gbMb94GNwdogai6fA3vTrALH8eoNJKqPWn9KyeBMhUQLpsN5ePJkZdHsPmyDsECNLRaYiposqDDqsbk3ANk9hbsSgmVq7G",
        basic => "Ky6vrNCdFUhcqGhh2PtMnLsKXx7Q5T6vkiQStmneCFE5MAJwpYWa",
    },
);

my $tests = 1;

# testing for compatibility with other bip39 tools
foreach my $tdata (@test_data) {
    $tests += 3;
    my $from_mnemonic = Bitcoin::Crypto::ExtPrivateKey->fromMnemonic($tdata->{mnemonic}, $tdata->{passphrase}, $tdata->{lang});
    my $from_seed = Bitcoin::Crypto::ExtPrivateKey->fromHexSeed($tdata->{seed});
    my $exported = $from_mnemonic->toSerializedBase58();
    is($exported, encode_base58check($from_mnemonic->toSerialized()), "serialization is consistent");
    is($exported, $from_seed->toSerializedBase58(), "importing is consistent");
    is($exported, $tdata->{key}, "valid extended key result");

    $tests += 4;
    my $from_serialized = Bitcoin::Crypto::ExtPrivateKey->fromSerializedBase58($tdata->{key});
    my $extpublic = $from_serialized->getPublicKey();
    my $basic_private = $from_serialized->getBasicKey();
    my $basic_public = $extpublic->getBasicKey();
    is(ref $basic_private, "Bitcoin::Crypto::PrivateKey", "basic private key created");
    is(ref $basic_public, "Bitcoin::Crypto::PublicKey", "basic public key created");
    is($basic_private->getPublicKey()->toBytes(), $basic_public->toBytes(), "keys match");

    my $basic_derived = $from_serialized->deriveKey("m/0")->getBasicKey();
    is($basic_derived->toWif(), $tdata->{basic}, "derived basic private key ok");
}

# generating english mnemonics
for my $bits (map { 128 + $_ * 32 } 0 .. 4) {
    $tests += 2;
    my $mnemonic = Bitcoin::Crypto::ExtPrivateKey->generateMnemonic($bits, "en");
    my $length = $bits / 8 - 4;
    ok($mnemonic =~ /^(\w+ ?){$length}$/, "generated mnemonic looks valid ($bits bits)");
    try {
        Bitcoin::Crypto::ExtPrivateKey->fromMnemonic($mnemonic, "", "en");
        pass("generated mnemonic can be imported");
    } catch {
        fail("generated mnemonic is not importable");
    };
}

done_testing($tests);
