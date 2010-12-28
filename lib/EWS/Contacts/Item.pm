package EWS::Contacts::Item;
BEGIN {
  $EWS::Contacts::Item::VERSION = '1.103620';
}
use Moose;

use List::MoreUtils 'uniq';
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
        my @numbers = map {(defined and length) ? $_ : ()} 
                      _parse_phone_number($entry->{'_'});
        next if scalar @numbers == 0;

        push @{ $entries->{$type} }, @numbers;
    }

    return $entries;
}

sub _parse_phone_number {
    my $number = shift; 
    $number =~ s/\s+//g;
    return uniq split m/\D/, $number;
        # we don't sort this list, because the field content may be ordered
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
