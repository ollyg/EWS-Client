package EWS::Calendar::Read;
use Moose;

with 'EWS::Calendar::Role::Process';
use EWS::Calendar::Query;

has username => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has password => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has server => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

sub view {
    my $self = shift;
    my $query = EWS::Calendar::Query->new(@_);
    return $self->run($query);
}

__PACKAGE__->meta->make_immutable;
1;
