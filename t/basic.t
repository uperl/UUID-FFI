use strict;
use warnings;
use 5.010;
use Test::More tests => 1;
use UUID::FFI;

my $uuid = UUID::FFI->new_random;
isa_ok $uuid, 'UUID::FFI';
