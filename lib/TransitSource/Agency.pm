
package TransitSource::Agency;

use strict;
use warnings;

use base qw(Class::Accessor);

use TransitSource::DataSource;
use TransitSource::Generator;

__PACKAGE__->mk_accessors(qw(key name url));

sub new_from_dict {
    my ($class, $key, $dict) = @_;

    my $self = bless {}, $class;

    $self->{key} = $key;
    $self->{data_source} = TransitSource::DataSource->new_from_agency_dict($dict);
    $self->{routes} = {};
    $self->{stations} = {};
    $self->{stops} = {};
    $self->{name} = {};
    $self->{url} = {};

    return $self;
}

sub fetch {
    my ($self, $data_dir) = @_;

    return $self->{data_source}->fetch($data_dir);
}

sub build_output {
    my ($self, $data_dir, $output_dir) = @_;

    $self->{data_source}->populate_data($data_dir, $self);

    TransitSource::Generator->write_agency_data($self, $output_dir);
}

sub add_route {
    my ($self, $route) = @_;

    my $id = $route->id;
    $self->{routes}{$id} = $route;
}

sub add_station {
    my ($self, $station) = @_;

    my $id = $station->id;
    $self->{stations}{$id} = $station;
}

sub add_stop {
    my ($self, $stop) = @_;

    my $id = $stop->id;
    $self->{stops}{$id} = $stop;
}

sub routes {
    my ($self) = @_;

    return [ values %{$self->{routes}} ];
}

sub route {
    my ($self, $route_key) = @_;

    return $self->{routes}{$route_key};
}

sub stations {
    my ($self) = @_;

    return [ values %{$self->{stations}} ];
}

sub station {
    my ($self, $station_key) = @_;

    return $self->{stations}{$station_key};
}

sub stops {
    my ($self) = @_;

    return [ values %{$self->{stops}} ];
}

sub stop {
    my ($self, $stop_key) = @_;

    return $self->{stops}{$stop_key};
}

sub as_json_dict {
    my ($self) = @_;

    my $ret = {};
    $ret->{id} = $self->key;
    $ret->{name} = $self->name if defined($self->name);
    $ret->{url} = $self->url if defined($self->url);
    return $ret;
}

1;
