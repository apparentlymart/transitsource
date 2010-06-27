
package TransitSource::DataSource;

use strict;
use warnings;

my %drivers;

BEGIN {
    %drivers = (
        gtfs => 'TransitSource::DataSource::GTFS',
    );

    foreach my $driver (values %drivers) {
        eval "use $driver;";
        if ($@) {
            die $@;
        }
    }
};

sub new_from_agency_dict {
    my ($class, $agency_dict) = @_;

    my $type = $agency_dict->{data_type};
    my $driver = $drivers{$type} or die "Unsupported data source type $type\n";

    return $driver->new_from_agency_dict($agency_dict);
}


1;
