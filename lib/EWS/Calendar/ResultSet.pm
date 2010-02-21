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
    my ($class, @rest) = @_;
    my $params = (scalar @rest == 1 ? $rest[0] : {@rest});

    # promote hashes returned from Exchange into Item objects
    $params->{items} = [ map { EWS::Calendar::Item->new($_) }
                             @{$params->{items}} ];
    return $params;
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
