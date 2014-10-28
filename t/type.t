use strict;
use warnings;
use v5.10;
use Test::More tests => 2;
use UUID::FFI;

is(UUID::FFI->new_random->type, 'random', 'type = random');
is(UUID::FFI->new_time->type,   'time', 'type = time');
