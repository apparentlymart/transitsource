
=head1 NAME

TransitSource - Builds JSON-formatted summaries of public transit data feeds

=cut

package TransitSource;

use strict;
use warnings;

use YAML::Syck qw();
use JSON::Any;
use Carp;

use TransitSource::Agency;

sub new {
    my ($class, %params) = @_;

    my $agencies_file = delete $params{agencies_file} or Carp::croak "Must provide agencies_file";
    Carp::croak("Unsupported argument(s): ".join(', ', keys %params)) if %params;

    my $agencies = YAML::Syck::LoadFile($agencies_file);

    my $self = bless {}, $class;
    $self->{agencies} = $agencies;

    return $self;
}

sub all_agencies {
    my ($self) = @_;

    my $agencies = $self->{agencies};

    my $ret = {};
    foreach my $agency_key (keys %$agencies) {
        $ret->{$agency_key} = TransitSource::Agency->new_from_dict($agency_key, $agencies->{$agency_key});
    }
    return $ret;
}

sub agency {
    my ($self, $agency_key) = @_;

    my $agencies = $self->{agencies};

    my $agency_dict = $agencies->{$agency_key};
    return undef unless $agency_dict;

    return TransitSource::Agency->new_from_dict($agency_key, $agency_dict);
}


1;
