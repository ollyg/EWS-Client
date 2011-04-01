package EWS::Client;
BEGIN {
  $EWS::Client::VERSION = '1.110910';
}
use Moose;

with qw/
    EWS::Client::Role::SOAP
    EWS::Client::Role::GetItem
    EWS::Client::Role::FindItem
/;
use EWS::Client::Contacts;
use EWS::Client::Calendar;
use URI::Escape ();

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

has contacts => (
    is => 'ro',
    isa => 'EWS::Client::Contacts',
    lazy_build => 1,
);

sub _build_contacts {
    my $self = shift;
    return EWS::Client::Contacts->new({ client => $self });
}

has calendar => (
    is => 'ro',
    isa => 'EWS::Client::Calendar',
    lazy_build => 1,
);

sub _build_calendar {
    my $self = shift;
    return EWS::Client::Calendar->new({ client => $self });
}

sub BUILDARGS {
    my ($class, @rest) = @_;
    my $params = (scalar @rest == 1 ? $rest[0] : {@rest});

    # collect EWS password from environment as last resort
    $params->{password} ||= $ENV{EWS_PASS};

    # URI escape the username and password
    $params->{username} ||= '';
    $params->{username} = URI::Escape::uri_escape($params->{username});
    $params->{password} = URI::Escape::uri_escape($params->{password});

    return $params;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

# ABSTRACT: Microsoft Exchange Web Services Client


__END__
=pod

=head1 NAME

EWS::Client - Microsoft Exchange Web Services Client

=head1 VERSION

version 1.110910

=head1 SYNOPSIS

Set up your Exchange Web Services client. I<You will need HTTP Basic Access
Auth enabled on the Exchange server to use this module>:

 use EWS::Client;
 use DateTime;
 
 my $ews = EWS::Client->new({
     server      => 'exchangeserver.example.com',
     username    => 'oliver',
     password    => 's3krit', # or set in $ENV{EWS_PASS}
 });

Then perform operations on the Exchange server:

 my $entries = $ews->calendar->retrieve({
     start => DateTime->now(),
     end   => DateTime->now->add( months => 1 ),
 });
 
 print "I retrieved ". $entries->count ." items\n";
 
 while ($entries->has_next) {
     print $entries->next->Subject, "\n";
 }
 
 my $contacts = $ews->contacts->retrieve;

=head1 DESCRIPTION

This module acts as a client to the Microsoft Exchange Web Services API. From
here you can access calendar and contact entries in a nicely abstracted
fashion. Query results are generally available in an iterator and convenience
methods exist to access the properties of each entry.

=head1 METHODS

=head2 EWS::Client->new( \%arguments )

Instantiates a new EWS client. There won't be any connection to the server
until you call one of the calendar or contacts retrieval methods.

=over 4

=item C<server> => Fully Qualified Domain Name (required)

The host name of the Exchange server to which the module should connect.

=item C<username> => String (required)

The account username under which the module will connect to Exchange. This
value will be URI encoded by the module.

=item C<password> => String OR via C<$ENV{EWS_PASS}> (required)

The password of the account under which the module will connect to Exchange.
This value will be URI encoded by the module. You can also provide the
password via the C<EWS_PASS> environment variable.

=item C<use_negotiated_auth> => True or False value

The module will assume you wish to use HTTP Basic Access Auth, in which case
you should enable that in your Exchange server. However for negotiated methods
such as NTLM set this to a True value. For NTLM please also install the
L<LWP::Authen::NTlm> module.

=item C<schema_path> => String (optional)

A folder on your file system which contains the WSDL and two further Schema
files (messages, and types) which describe the Exchange 2007 Web Services SOAP
API. They are shipped with this module so your providing this is optional.

=item C<server_version> => String (optional)

In each request to the server is specified the API version we expect to use.
By default this is set to C<Exchange2007_SP1> but you have the opportunity to
set it to C<Exchange2007> if you wish using this option.

=back

=head2 $ews->calendar()

Retrieves the L<EWS::Client::Calendar> object which allows search and
retrieval of calendar entries and their various properties. See that linked
manual page for more details.

=head2 $ews->contacts()

Retrieves the L<EWS::Client::Contacts> object which allows retrieval of
contact entries and their telephone numbers. See that linked manual page for
more details.

=head1 KNOWN ISSUES

=over 4

=item * No handling of time zone information, sorry.

=item * The C<SOAPAction> Header might be wrong for Exchange 2010.

=back

=head1 REQUIREMENTS

=over 4

=item * L<Moose>

=item * L<MooseX::Iterator>

=item * L<XML::Compile::SOAP>

=item * L<DateTime>

=item * L<DateTime::Format::ISO8601>

=item * L<HTML::Strip>

=item * L<URI::Escape>

=item * L<File::ShareDir>

=back

=head1 THANKS

To Greg Shaw for sending patches for NTLM Authentication support and User
Impersonation.

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

