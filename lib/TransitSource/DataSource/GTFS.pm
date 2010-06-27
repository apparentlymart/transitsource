
package TransitSource::DataSource::GTFS;

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;
use POSIX qw(strftime);
use Archive::Zip;
use Text::CSV;

use TransitSource::Route;

my %route_types = (
    0 => 'light_rail',
    1 => 'subway',
    2 => 'heavy_rail',
    3 => 'bus',
    4 => 'ferry',
    5 => 'cable_car',
    6 => 'gondola',
    7 => 'funicular',
);

sub new_from_agency_dict {
    my ($class, $agency_dict) = @_;

    my $archive = $agency_dict->{gtfs_archive} or die "Must specify gtfs_archive for a GTFS data source\n";
    my $source = $agency_dict->{gtfs_source} or die "Must specify gtfs_source for a GTFS data source\n";
    my $agency_id = $agency_dict->{gtfs_agency_id} || "";

    my $self = bless {}, $class;

    $self->{archive} = $archive;
    $self->{source} = $source;
    $self->{agency_id} = $agency_id;

    return $self;
}

sub fetch {
    my ($self, $data_dir) = @_;

    my $ua = LWP::UserAgent->new();
    $ua->agent('TransitSource');

    my $req = HTTP::Request->new(GET => $self->{source});
    my $archive_file = "$data_dir/".$self->{archive};
    my ($archive_dir) = ($archive_file =~ m!^(.*?)/[^/]+$!);

    if (-f $archive_file) {
        my @stat = stat($archive_file);
        my $mtime = $stat[9];
        $req->if_modified_since($mtime);
    }

    warn "Retrieving $self->{source}...\n";
    my $res = $ua->request($req);

    if ($res->is_success) {
        warn "Got archive. Saving.\n";
        mkdir($archive_dir);
        open(ARCHIVE, '>', $archive_file);
        binmode(ARCHIVE);
        print ARCHIVE $res->content;
        close(ARCHIVE);
    }
    else {
        warn "$self->{source} returned ".$res->status_line."\n";
    }
}

sub populate_data {
    my ($self, $data_dir, $agency) = @_;

    my $archive = $data_dir."/".$self->{archive};
    my $zip = Archive::Zip->new($archive);

    unless ($zip) {
        die "Can't open GTFS archive $data_dir for agency ".$agency->key."; perhaps you need to run fetch?\n";
    }

    my $agencies_data = _get_zip_file_data($zip, 'agency.txt');
    my $agency_id = $self->{agency_id};
    my $agency_row;

    if ($agency_id) {
        ($agency_row) = grep { $_->{agency_id} eq $agency_id } @$agencies_data;
    }
    else {
        $agency_row = $agencies_data->[0];
        $agency_id = $agency_row->{agency_id} || '';
    }

    unless ($agency_row) {
        die "Unable to find the right agency row\n";
    }

    $agency->name($agency_row->{agency_name});
    $agency->url($agency_row->{agency_url});

    my $routes_data = _get_zip_file_data($zip, 'routes.txt');

    foreach my $route_row (@$routes_data) {
        $route_row->{agency_id} ||= '';
        next unless $route_row->{agency_id} eq $agency_id;

        my $id = $route_row->{route_id} || undef;
        my $short_name = $route_row->{route_short_name} || undef;
        my $long_name = $route_row->{route_long_name} || undef;
        my $desc = $route_row->{route_desc} || undef;
        my $url = $route_row->{route_url} || undef;
        my $color = $route_row->{route_color} || 'ffffff';
        my $contrast_color = $route_row->{route_text_color} || '000000';
        my $type = undef;
        $type = $route_types{$route_row->{route_type}} if $route_row->{route_type};

        $color = '#'.$color if defined($color);
        $contrast_color = '#'.$contrast_color if defined($contrast_color);

        my $route = TransitSource::Route->new({
            id => $id,
            short_name => $short_name,
            long_name => $long_name,
            desc => $desc,
            url => $url,
            color => $color,
            constrast_color => $contrast_color,
            type => $type,
        });

        $agency->add_route($route);
    }

}

sub _get_zip_file_data {
    my ($zip, $fn) = @_;

    my $member = $zip->memberNamed($fn);
    return [] unless $member;

    return _csv_to_hashes($member->contents);
}

sub _csv_to_hashes {
    my ($csv_data) = @_;

    my @csv_lines = split(/\n/, $csv_data);
    $csv_data = undef; # free the string now that we have it as an array.
    chomp @csv_lines; # in case we have windows line endings

    my $csv = Text::CSV->new({ binary => 1 });

    my $header_row = shift @csv_lines;
    $header_row =~ s!\s*$!!;
    utf8::decode($header_row);
    my %column_keys = ();

    $csv->parse($header_row);
    my $idx = 0;
    foreach my $column_key ($csv->fields) {
        $column_keys{$idx++} = $column_key;
    }

    my @ret = ();
    foreach my $line (@csv_lines) {
        $line =~ s!\s*$!!;
        $csv->parse($line);
        my $idx = 0;
        my $row = {};
        foreach my $value ($csv->fields) {
            $value =~ s!\s*$!! if defined $value; # some agencies space-pad their values :(
            $row->{$column_keys{$idx++}} = $value;
        }
        push @ret, $row;
    }

    return \@ret;
}

1;
