
package TransitSource::Generator;

use strict;
use warnings;
use JSON::XS;

my $json = JSON::XS->new();
$json->pretty(1);

sub write_agency_data {
    my ($class, $agency, $output_dir) = @_;

    my $agency_output_dir = "$output_dir/agencies/".$agency->key;
    mkdir("$output_dir/agencies");
    mkdir($agency_output_dir);

    write_json("$output_dir/agencies/".$agency->key, $agency->as_json_dict);

    my $routes = $agency->routes;
    write_json("$agency_output_dir/routes", [ map { $_->as_json_dict } @$routes ]);
}

sub write_agency_summary_file {
    my ($class, $agencies, $output_dir) = @_;

    write_json("$output_dir/agencies", [ map { $_->as_json_dict } sort { $a->name cmp $b->name } @$agencies ]);
}

sub write_json {
    my ($fn, $dict) = @_;

    # Shorthand for the common case of returning a list.
    if (ref $dict eq 'ARRAY') {
        $dict = { items => $dict };
    }

    open(OUT, '>', $fn.".json");
    print OUT $json->encode($dict);
    close(OUT);
}

1;
