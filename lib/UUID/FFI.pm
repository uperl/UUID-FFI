package UUID::FFI;

use strict;
use warnings;
use 5.010;
use FFI::Raw ();
use FFI::CheckLib qw( find_lib );
use FFI::Util ();
use Carp qw( croak );
use base qw( FFI::Raw::Ptr );
use overload '<=>' => sub { $_[0]->compare($_[1]) },
             '""'  => sub { shift->as_hex         },
             fallback => 1;

# TODO: as_bin or similar

# ABSTRACT: Universally Unique Identifiers FFI style
# VERSION

=head1 SYNOPSIS

 my $uuid = UUID::FFI->new_random;
 say $uuid->as_hex;

=head1 DESCRIPTION

This module provides an FFI interface to C<libuuid>.
C<libuuid> library is used to generate unique identifiers
for objects that may be accessible beyond the local system

=cut

use constant {
  _lib => find_lib( lib => 'uuid' ),
};

use constant _time_t => eval 'FFI::Raw::'.FFI::Util::_lookup_type("time_t");

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

use constant _time => FFI::Raw->new(
  _lib, 'uuid_time',
  _time_t,
  FFI::Raw::ptr, FFI::Raw::ptr,
);

=head1 CONSTRUCTORS

=head2 new

 my $uuid = UUID::FFI->new($hex);

Create a new UUID object from the hex representation C<$hex>.

=cut

sub new
{
  my($class, $hex) = @_;
  croak "usage: UUID::FFI->new($hex)" unless $hex;
  my $self = bless \_malloc->call(16), $class;
  my $r = _parse->call($hex, $self);
  croak "$hex is not a valid hex UUID" if $r != 0; 
  $self;
}

=head2 new_random

 my $uuid = UUID::FFI->new_random;

Create a new UUID object with a randomly generated value.

=cut

sub new_random
{
  my($class) = @_;
  my $self = bless \_malloc->call(16), $class;
  _generate_random->call($self);
  $self;
}

=head2 new_time

 my $uuid = UUID::FFI->new_time;

Create a new UUID object generated using the time and mac address.
This can leak information about when and where the UUID was generated.

=cut

sub new_time
{
  my($class) = @_;
  my $self = bless \_malloc->call(16), $class;
  _generate_time->call($self);
  $self;
}

=head2 new_null

 my $uuid = UUID::FFI->new_null;

Create a new UUID C<NULL UUID>  object (all zeros).

=cut

sub new_null
{
  my($class) = @_;
  my $self = bless \_malloc->call(16), $class;
  _clear->call($self);
  $self;
}

=head1 METHODS

=head2 is_null

 my $bool = $uuid->is_null;

Returns true if the UUID is C<NULL UUID>.

=cut

*is_null = FFI::Raw->new(
  _lib, 'uuid_is_null',
  FFI::Raw::int,
  FFI::Raw::ptr,
)->coderef;

=head2 clone

 my $uuid2 = $uuid->clone;

Create a new UUID object with the identical value to the original.

=cut

sub clone
{
  my($self) = @_;
  my $other = bless \_malloc->call(16), ref $self;
  _copy->call($other, $self);
  $other;
}

=head2 as_hex

 my $hex = $uuid->as_hex;
 my $hex = "$uuid";

Returns the hex representation of the UUID.  The stringification of
L<UUID::FFI> uses this function, so you can also use it in a double quoted string.

=cut

sub as_hex
{
  my($self) = @_;
  my $data = "x" x 36;
  my $ptr = unpack 'L!', pack 'P', $data;
  _unparse->call($self, $ptr);
  $data;
}

=head2 compare

 my $cmp = $uuid1->compare($uuid2);
 my $cmp = $uuid1 <=> $uuid2;
 my @sorted_uuids = sort { $a->compare($b) } @uuid;
 my @sorted_uuids = sort { $a <=> $b } @uuid;

Returns an integer less than, equal to or greater than zero
if C<$uuid1> is found, respectively, to be lexicographically
less than, equal, or greater that C<$uuid2>.  The C<E<lt>=E<gt>>
is also overloaded so you can use that too.

=cut

*compare = FFI::Raw->new(
  _lib, 'uuid_compare',
  FFI::Raw::int,
  FFI::Raw::ptr, FFI::Raw::ptr,
)->coderef;

my %type_map = (
  1 => 'time',
  4 => 'random',
);

=head2 type

 my $type = $uuid->type;

Returns the type of UUID, either C<time> or C<random>,
if it can be identified.

=cut

sub type
{
  my($self) = @_;
  my $r = _type->call($self);
  $type_map{$r} // croak "illegal type: $r";
}

my @variant = qw( ncs dce microsoft other );

=head2 variant

 my $variant = $uuid->variant

Returns the variant of the UUID, either C<ncs>, C<dce>, C<microsoft> or C<other>.

=cut

sub variant
{
  my($self) = @_;
  my $r = _variant->call($self);
  $variant[$r] // croak "illegal varient: $r";
}

=head2 time

 my $time = $uuid->time;

Returns the time the UUID was generated.  The value returned is in seconds
since the UNIX epoch, so is compatible with perl builtins like L<time|perlfunc#time> and
C<localtime|perlfunc#localtime>.

=cut

sub time
{
  my($self) =@_;
  _time->call($self, undef);
}

sub DESTROY
{
  my($self) = @_;
  _free->call($self);
}

1;
