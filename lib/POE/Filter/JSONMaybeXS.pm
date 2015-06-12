package POE::Filter::JSONMaybeXS;
# ABSTRACT: A POE filter using JSON::MaybeXS

use Carp;
use JSON::MaybeXS;

use strict;
use warnings;

use base qw( POE::Filter );

sub BUFFER () { 0 }
sub OBJ    () { 1 }

sub new {
  my $class = shift;
  croak "$class requires an even number of parameters" if @_ % 2;
  my %opts = @_;
  bless( [
    [],                         # BUFFER
    JSON::MaybeXS->new( %opts ) # OBJ
  ], ref $class || $class );
}

sub get {
  my ($self, $lines) = @_;
  my $ret = [];

  foreach my $json (@$lines) {
    if ( my @jsons = eval { $self->[ OBJ ]->incr_parse( $json ) } ) {
      push( @$ret, @jsons );
    } else {
      $self->incr_skip;
      warn "Couldn't convert json: $@";
    }
  }
  return $ret;
}

sub get_one_start {
    my ($self, $lines) = @_;
    $lines = [ $lines ] unless ( ref( $lines ) );
    push( @{ $self->[ BUFFER ] }, @{ $lines } );
}

sub get_one {
  my $self = shift;
  my $ret = [];

  if ( my $line = shift ( @{ $self->[ BUFFER ] } ) ) {
    if ( my @jsons = eval { $self->[ OBJ ]->incr_parse( $line ) } ) {
      push( @$ret, @jsons );
    } else {
      $self->incr_skip;
      warn "Couldn't convert json: $@";
    }
  }

  return $ret;
}

sub put {
  my ($self, $objects) = @_;
  my $ret = [];

  foreach my $obj (@$objects) {
    if ( my $json = eval { $self->[ OBJ ]->encode( $obj ) } ) {
      push( @$ret, $json );
    } else {
      warn "Couldn't convert object to json\n";
    }
  }
  
  return $ret;
}

1;

__END__

=head1 SYNOPSIS

  use POE::Filter::JSONMaybeXS;

  my $filter = POE::Filter::JSONMaybeXS->new(
    allow_nonref => 1,  # see the JSON::MaybeXS new options
  );
  my $obj = { foo => 1, bar => 2 };
  my $json_array = $filter->put( [ $obj ] );
  my $obj_array = $filter->get( $json_array );

  use POE qw( Filter::Stackable Filter::Line Filter::JSONMaybeXS );

  my $filter = POE::Filter::Stackable->new();
  $filter->push(
    POE::Filter::JSONMaybeXS->new(),
    POE::Filter::Line->new(),
  );

=head1 DESCRIPTION

Uses B<incr_parse>, so can handle incremental JSON...

More documentation to come...

More tests to come...

Based on L<POE::Filter::JSON>

=cut
