package EWS::Client::Role::FindItem;
BEGIN {
  $EWS::Client::Role::FindItem::VERSION = '1.103620';
}
use Moose::Role;

# XXX This really needs to live somewhere else, but it can squat here for a
#  while
my @distinguished_folder_names = qw(
    calendar contacts deleteditems drafts inbox journal notes outbox sentitems
    tasks msgfolderroot publicfoldersroot root junkemail searchfolders
    voicemail
);

has FindItem => (
    is => 'ro',
    isa => 'CodeRef',
    lazy_build => 1,
);

sub _build_FindItem {
    my $self = shift;
    return $self->wsdl->compileClient(
        operation => 'FindItem',
        transport => $self->transporter->compileClient(
            action => 'http://schemas.microsoft.com/exchange/services/2006/messages/FindItem' ),
    );
}

# Performs a simple FindItem call, with no paging, grouping, or sorting, and
#  only hand-rolled filtering available
# Arguments:
#   Traversal is a string that can be either 'Shallow' or 'SoftDeleted', Deep
#     is not supported by EWS for FindItem or FindFolder
#   BaseShape can be "IdOnly", "Default" (AllProperties is not permitted, due
#     to an EWS restriction on returning calculated properties, and a max
#     returned record size of 512 bytes)
#   AdditionalProperties is an array(ref) of URIs for fields.  This function 
#     will croak if a property that EWS rejects is requested.
#   InFolders is an arrayref of distinguished folder names or FolderIds (either
#     bare IDs, or structures as returned in ParentFolderId fields)
#   Restriction is a hash in the format required by EWS (XXX ick!)
sub FindItems_Simple {
    my ($self, $opts) = @_;

    # base parameters
    my %request = (
        (exists $opts->{impersonate} ? (
            Impersonation => {
                ConnectingSID => {
                    PrimarySmtpAddress => $opts->{impersonate},
                }
            },
        ) : ()),
        RequestVersion => {
            Version => $self->server_version,
        },
        ItemShape => {
            BaseShape => $opts->{BaseShape} || 'Default',
        },
        Traversal => $opts->{Traversal} || 'Shallow',
        ParentFolderIds => {
            cho_FolderId => [ ],
        },
    );

    # folder ids
    foreach my $folder (@{$opts->{InFolders}}) {
        # silently ignore input that is patently wrong
        next if ref $folder and ref $folder ne 'HASH';

        my $folderid = $folder;

        if (not ref $folder) {
            if (grep($folder, @distinguished_folder_names)) {
                $folderid = {
                    DistinguishedFolderId => { Id => $folder }
                };
            } else {
                $folderid = {
                    FolderId => { Id => $folder }
                };
            }
        }

        push(@{$request{ParentFolderIds}{cho_FolderId}}, $folderid);
    }

    # Sorting (not for now)

    # Restrictions
    if (defined $opts->{Restriction}) {
        $request{Restriction} = $opts->{Restriction};
    }

    return scalar $self->FindItem->(%request);
}

no Moose::Role;
1;

