use strict;

# this is a little role/trait that allows attributes to indicate that they
# wish to be serialized by the main role down at the bottom
package EWS::Client::Role::Trait::Serialized;
BEGIN {
  $EWS::Client::Role::Trait::Serialized::VERSION = '1.103620';
}
use Moose::Role;

has serialization_helper => (
    is => 'rw',
    isa => 'CodeRef',
    predicate => 'has_serialization_helper',
);

no Moose::Role;

# Note: see http://docs.activestate.com/activeperl/5.12/lib/Moose/Cookbook/Meta/Recipe3.html
package Moose::Meta::Attribute::Custom::Trait::Serialized;
sub register_implementation {'EWS::Client::Role::Trait::Serialized'}

# here's the main role, which adds a method which will serialize the object in
# a manner suitable for inclusion in an Items stanza to be processed in
# XML::Compile, and sent in an EWS web request
package EWS::Client::Role::Serializer;
BEGIN {
  $EWS::Client::Role::Serializer::VERSION = '1.103620';
}

use Moose::Role;

has SerializationItemName => (
    is => 'ro',
    isa => 'Str',
    default => 'Item',
);

# arguments:
#  attr_names: a optional list of attributes to serialize, they don't 
#   necessarily need to implement the Serialized trait.  In the case 
#   where no list is passed, all attributes implementing the Serialized trait
#   are serialized
sub serialize {
    my ($self, $attr_names) = @_;

    my $result;
    my @attributes;

    if (defined $attr_names) {
        @attributes = map { $self->meta->find_attribute_by_name($_) }
                            @$attr_names;
    } else {
        @attributes = grep { $_->does('EWS::Client::Role::Trait::Serialized') }
                              $self->meta->get_all_attributes();
    }

    # perform serialization on all of the attributes which have indicated that
    # they wish to be serialized (via a "Serialized" entry in their traits)
    foreach my $attribute (@attributes) {
        next unless $attribute->has_value($self);

        my $reader = $attribute->get_read_method;
        my $value = $self->$reader;

        next if not defined $value;

        unless ($attribute->has_serialization_helper) {
            # default case is to just use the attribute name and value
            $result->{$attribute->name} = $value;
        } else {
            # otherwise call the serialization helper function provided
            my $serialized_value = $attribute->serialization_helper->($self, $value);
            next if not defined $serialized_value;

            $result->{$attribute->name} = $serialized_value;
        }
    }

    # finally, wrap the item in it's little hashref that tells EWS what type
    # of item it is.  This will be placed in an array of cho_BlahBlah
    return { $self->SerializationItemName => $result };
}

no Moose::Role;

1;
