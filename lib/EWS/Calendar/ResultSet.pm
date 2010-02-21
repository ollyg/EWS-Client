package EWS::Calendar::ResultSet;
use Moose;
use MooseX::Iterator;

use EWS::Calendar::Item;

has items => (
    is => 'ro',
    isa => 'ArrayRef',
    required => 1,
);

sub BUILDARGS {
    my ($class, @params) = @_;
    my $items = (scalar @params == 1 ? $params[0]->{items} : $params[1]);
    # promote hashes returned from Exchange into Item objects
    $items = [ map { EWS::Calendar::Item->new($_) } @{$items} ];
    return {items => $items};
}

sub count {
    my $self = shift;
    return scalar @{$self->items};
}

has iter => (
    metaclass => 'Iterable',
    iterate_over => 'items',
);

__PACKAGE__->meta->make_immutable;
no Moose;
1;
