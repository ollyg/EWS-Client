package EWS::Contacts::Item;
BEGIN {
  $EWS::Contacts::Item::VERSION = '1.113000';
}
use Moose;

use Encode;

has DisplayName => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has PhoneNumbers => (
    is => 'ro',
    isa => 'HashRef[ArrayRef]',
    default => sub { {} },
);

sub BUILDARGS {
    my ($class, @rest) = @_;
    my $params = (scalar @rest == 1 ? $rest[0] : {@rest});

    $params->{'PhoneNumbers'} = _build_PhoneNumbers($params->{'PhoneNumbers'});

    foreach my $key (keys %$params) {
        if (not ref $params->{$key}) {
            $params->{$key} = Encode::encode('utf8', $params->{$key});
        }
    }

    return $params;
}

sub _build_PhoneNumbers {
    my $numbers = shift;
    my $entries = {};

    return {} if !exists $numbers->{'Entry'}
                 or ref $numbers->{'Entry'} ne 'ARRAY'
                 or scalar @{ $numbers->{'Entry'} } == 0;

    foreach my $entry (@{ $numbers->{'Entry'} }) {
        next if !defined $entry->{'Key'}
                or $entry->{'Key'} =~ m/(?:Fax|Callback|Isdn|Pager|Telex|TtyTdd)/i;

        my $type = $entry->{'Key'};
        $type =~ s/(\w)([A-Z0-9])/$1 $2/g; # BusinessPhone -> Business Phone

        # get numbers and set mapping to this name, but skip blanks
        next unless $entry->{'_'};
        push @{ $entries->{$type} }, $entry->{'_'};
    }

    return $entries;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
