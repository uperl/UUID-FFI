package UUID::FFI;

use strict;
use warnings;
use v5.10;
use FFI::Raw;
use FFI::CheckLib;
use Carp qw( croak );
use base qw( FFI::Raw::Ptr );
use overload '""' => sub { shift->as_hex };
use overload fallback => 1;

# TODO: uuid_time
# TODO: overload <=>

# ABSTRACT: Universally Unique Identifiers FFI style
# VERSION

use constant {
  _lib => find_lib( lib => 'uuid' ),
  
};

use constant _malloc => FFI::Raw->new(
  undef, 'malloc',
  FFI::Raw::ptr,
  FFI::Raw::int,
);

use constant _free => FFI::Raw->new(
  undef, 'free',
  FFI::Raw::void,
  FFI::Raw::ptr,
);

use constant _generate_random => FFI::Raw->new(
  _lib, 'uuid_generate_random',
  FFI::Raw::void,
  FFI::Raw::ptr,
);

use constant _generate_time => FFI::Raw->new(
  _lib, 'uuid_generate_time',
  FFI::Raw::void,
  FFI::Raw::ptr,
);

use constant _unparse => FFI::Raw->new(
  _lib, 'uuid_unparse',
  FFI::Raw::void,
  FFI::Raw::ptr, FFI::Raw::ptr,
);

use constant _parse => FFI::Raw->new(
  _lib, 'uuid_parse',
  FFI::Raw::int,
  FFI::Raw::str, FFI::Raw::ptr,
);

use constant _copy => FFI::Raw->new(
  _lib, 'uuid_copy',
  FFI::Raw::void,
  FFI::Raw::ptr, FFI::Raw::ptr,
);

use constant _clear => FFI::Raw->new(
  _lib, 'uuid_clear',
  FFI::Raw::void,
  FFI::Raw::ptr,
);

use constant _type => FFI::Raw->new(
  _lib, 'uuid_type',
  FFI::Raw::int,
  FFI::Raw::ptr,
);

use constant _variant => FFI::Raw->new(
  _lib, 'uuid_variant',
  FFI::Raw::int,
  FFI::Raw::ptr,
);

sub new
{
  my($class, $hex) = @_;
  croak "usage: UUID::FFI->new($hex)" unless $hex;
  my $self = bless \_malloc->call(16), $class;
  my $r = _parse->call($hex, $self);
  croak "$hex is not a valid hex UUID" if $r != 0; 
  $self;
}

sub new_random
{
  my($class) = @_;
  my $self = bless \_malloc->call(16), $class;
  _generate_random->call($self);
  $self;
}

sub new_time
{
  my($class) = @_;
  my $self = bless \_malloc->call(16), $class;
  _generate_time->call($self);
  $self;
}

sub new_null
{
  my($class) = @_;
  my $self = bless \_malloc->call(16), $class;
  _clear->call($self);
  $self;
}

*is_null = FFI::Raw->new(
  _lib, 'uuid_is_null',
  FFI::Raw::int,
  FFI::Raw::ptr,
)->coderef;

sub clone
{
  my($self) = @_;
  my $other = bless \_malloc->call(16), ref $self;
  _copy->call($other, $self);
  $other;
}

sub as_hex
{
  my($self) = @_;
  my $data = "x" x 36;
  my $ptr = unpack 'L!', pack 'P', $data;
  _unparse->call($self, $ptr);
  $data;
}

*compare = FFI::Raw->new(
  _lib, 'uuid_compare',
  FFI::Raw::int,
  FFI::Raw::ptr, FFI::Raw::ptr,
)->coderef;

my %type_map = (
  1 => 'time',
  4 => 'random',
);

sub type
{
  my($self) = @_;
  my $r = _type->call($self);
  $type_map{$r} // croak "illegal type: $r";
}

my @variant = qw( ncs dce microsoft other );

sub variant
{
  my($self) = @_;
  my $r = _variant->call($self);
  $variant[$r] // croak "illegal varient: $r";
}

sub DESTROY
{
  my($self) = @_;
  _free->call($self);
}

1;
