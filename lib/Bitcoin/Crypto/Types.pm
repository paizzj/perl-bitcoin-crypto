package Bitcoin::Crypto::Types;

use Modern::Perl "2010";
use Type::Library -base;
use Type::Coercion;
use Types::Common::Numeric qw (assert_PositiveInt);
use Types::Standard qw(Int InstanceOf);
use Math::BigInt 1.999818 try => 'GMP';

__PACKAGE__->add_type(
	name => "IntMaxBits",
	parent => InstanceOf->of("Math::BigInt"),

	constraint_generator => sub {
		my $bits = assert_PositiveInt(shift) - 1;
		my $limit = Math::BigInt->new(2)->blsft($bits);
		return sub {
			return $_->bge(0) && $_->blt($limit);
		};
	},

	coercion_generator => sub {
		return Type::Coercion->new(
			type_coercion_map => [
				Int, q{Math::BigInt->new($_)},
			],
		);
	},

	message => sub {
		my $bits = shift;
		return "Value does not fit in $bits bits";
	},
);

1;
