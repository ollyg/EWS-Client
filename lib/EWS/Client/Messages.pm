package EWS::Client::Messages;
BEGIN {
  $EWS::Client::Messages::VERSION = '1.103620';
}
use Moose;

with 'EWS::Messages::Role::Sender';
with 'EWS::Messages::Role::Reader';
# could add future roles for updates, here

has client => (
    is => 'ro',
    isa => 'EWS::Client',
    required => 1,
    weak_ref => 1,
);

__PACKAGE__->meta->make_immutable;
no Moose;
1;

# Need to add docs
