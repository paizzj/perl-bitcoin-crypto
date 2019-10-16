package Bitcoin::Crypto::Bech32;

use Modern::Perl "2010";
use Exporter qw(import);
use Math::BigInt 1.999816 try => 'GMP';
use Carp qw(croak);

our @EXPORT_OK = qw(
	encode_bech32
	decode_bech32
	split_bech32
);

our %EXPORT_TAGS = (all => [@EXPORT_OK]);

my $CHECKSUM_SIZE = 6;

my @alphabet = qw(
	q p z r y 9 x 8
	g f 2 t v d w 0
	s 3 j n 5 4 k h
	c e 6 m u a 7 l
);

my %alphabet_mapped = map { $alphabet[$_] => $_ } 0 .. $#alphabet;

sub polymod
{
	my ($values) = @_;
	my @consts = (0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3);
	my $chk = 1;
	for my $val (@$values) {
		my $b = ($chk >> 25);
		$chk = ($chk & 0x1ffffff) << 5 ^ $val;
		for (0 .. 4) {
			$chk ^= ((($b >> $_) & 1) ? $consts[$_] : 0);
		}
	}
	return $chk;
}

sub hrp_expand
{
	my @hrp = split "", shift;
	my (@part1, @part2);
	for (@hrp) {
		my $val = ord;
		push @part1, $val >> 5;
		push @part2, $val & 31;
	}
	return [@part1, 0, @part2];
}

sub to_numarr
{
	my ($string) = @_;

	return [map { $alphabet_mapped{$_} } split "", $string];
}

sub create_checksum
{
	my ($hrp, $data) = @_;
	my $polymod = polymod([@{hrp_expand $hrp}, @{to_numarr $data}, (0) x $CHECKSUM_SIZE]) ^ 1;
	my $checksum;
	for (0 .. $CHECKSUM_SIZE - 1) {
		$checksum .= $alphabet[($polymod >> 5 * (5 - $_)) & 31];
	}
	return $checksum;
}

sub verify_checksum
{
	my ($hrp, $data) = @_;
	return polymod([@{hrp_expand $hrp}, @{to_numarr $data}]) == 1;
}

sub split_bech32
{
	my ($bech32enc) = @_;
	$bech32enc = lc $bech32enc
		if uc $bech32enc eq $bech32enc;

	croak {reason => "bech32_input_format", message => "bech32 string too long"}
		if length $bech32enc > 90;

	my @parts = split "1", $bech32enc;

	croak {reason => "bech32_input_format", message => "bech32 separator character missing"}
		if @parts < 2;

	my $data = pop @parts;

	@parts = (join("1", @parts), $data);

	croak {reason => "bech32_input_format", message => "incorrect length of bech32 human readable part"}
		if length $parts[0] < 1 || length $parts[0] > 83;
	croak {reason => "bech32_input_format", message => "illegal characters in bech32 human readable part"}
		if $parts[0] !~ /^[\x21-\x7e]+$/;
	croak {reason => "bech32_input_format", message => "incorrect length of bech32 data part"}
		if length $parts[1] < 6;
	my $chars = join "", @alphabet;
	croak {reason => "bech32_input_format", message => "illegal characters in bech32 data part"}
		if $parts[1] !~ /^[$chars]+$/;
	croak {reason => "bech32_input_checksum", message => "incorrect bech32 checksum"}
		unless verify_checksum(@parts);

	return @parts;
}

sub encode_bech32
{
	my ($hrp, $bytes) = @_;
	my $preserve = 0;
	++$preserve while substr($bytes, $preserve, 1) eq "\x00";
	my $number = Math::BigInt->from_bytes($bytes);
	my $result = "";
	my $size = scalar @alphabet;
	while ($number->is_pos()) {
		my $copy = $number->copy();
		$result = $alphabet[$copy->bmod($size)] . $result;
		$number->bdiv($size);
	}
	$result = $alphabet[0] x $preserve . $result;
	my $checksum = create_checksum($hrp, $result);
	return $hrp . 1 . $result . $checksum;
}

sub decode_bech32
{
	my ($hrp, $data) = split_bech32 @_;

	return ""
		if length $data == $CHECKSUM_SIZE;
	my @arr = @{to_numarr substr $data, 0, -$CHECKSUM_SIZE};
	my $preserve = 0;
	++$preserve while @arr > $preserve && $arr[$preserve] == 0;
	my $ret = pack("x$preserve");
	if ($preserve < @arr) {
		my $result = Math::BigInt->new(0);
		while (@arr) {
			my $current = shift @arr;
			my $step = Math::BigInt->new(scalar @alphabet)->bpow(scalar @arr)->bmul($current);
			$result->badd($step);
		}
		$ret .= $result->as_bytes();
	}
	return $ret;
}

1;

__END__
=head1 NAME

Bitcoin::Crypto::Bech32 - Bitcoin's Bech32 implementation in Perl (BIP173 compatible)

=head1 SYNOPSIS

	use Bitcoin::Crypto::Bech32 qw(:all);

	my $bech32str = encode_bech32(pack "A*", "hello");
	my $bytestr = decode_bech32($bech32str);

=head1 DESCRIPTION

Implementation of Bech32 algorithm with Math::BigInt (GMP).

=head1 FUNCTIONS

=head2 encode_bech32

=head2 decode_bech32

Basic bech32 encoding / decoding.
Encoding takes one argument which is byte string.
Decoding takes bech32-encoded string and croaks on errors.

=head2 split_bech32

Splits a bech32-encoded string into human-readable part and data part. Returns a list containing the two.
Performs all validity checks on the input. Croaks on every error.

=head1 SEE ALSO

=over 2

=item L<Bitcoin::Crypto::PrivateKey>

=item L<Bitcoin::Crypto::PublicKey>

=back

=cut