use strict;
use warnings;
use 5.010;
use Test::More tests => 1;
use UUID::FFI;

my $uuid = UUID::FFI->new_random;
like $uuid->variant, qr{^(ncs|dce|microsoft|other)$}, 'variant';
note $uuid->variant;
