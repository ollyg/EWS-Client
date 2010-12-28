package EWS::Calendar::Role::Reader;
BEGIN {
  $EWS::Calendar::Role::Reader::VERSION = '1.103620';
}
use Moose::Role;

with 'EWS::Calendar::Role::RetrieveWithinWindow';
use EWS::Calendar::Window;

sub retrieve {
    my ($self, $opts) = @_;
    return $self->retrieve_within_window({
        window => EWS::Calendar::Window->new($opts),
        %$opts,
    });
}

no Moose::Role;
1;
