
package TransitSource::Route;

use strict;
use warnings;

use base qw(Class::Accessor);

__PACKAGE__->mk_accessors(qw(id short_name long_name desc type url color contrast_color));


my %types = (
    'light_rail' => 'Light Rail',
    'subway' => 'Subway',
    'heavy_rail' => 'Heavy Rail',
    'bus' => 'Bus',
    'ferry' => 'Ferry',
    'cable_car' => 'Cable Car',
    'gondola' => 'Gondola',
    'funicular' => 'Funicular',
);

sub as_json_dict {
    my ($self) = @_;

    my $ret = {};

    foreach my $k (qw(id short_name long_name desc type url color contrast_color)) {
        $ret->{$k} = $self->$k if defined($self->$k);
    }

    return $ret;
}

1;

