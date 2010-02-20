package EWS::Calendar::Query;
use Moose;

has start => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has end => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

__PACKAGE__->meta->make_immutable;
no Moose;
1;

