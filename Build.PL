use strict;
use warnings;
use Module::Build;

my $rh_requires;

BEGIN {

    $rh_requires = {
        'perl'          => '5.010',
        'Geo::Distance::XS' => '0.08',
        'List::Util::WeightedRoundRobin' => '0.4',
        'List::Util' => '1.23',
        'List::MoreUtils' => '0.22',
        'Time::HiRes' => '1.9711',
        'HTTP::Request' => '5.827',
        'Net::Ping' => '2.33',
    };

# Hack for conditional dependencies.  The geocoder plugins are optional, but if
# they are installed, we do care that they are a recent version. This detects
# the modules, and adds version dependencies for any that are present.

    my %geocoder_min_versions = (
        'Bing'        => '0.10',
        'Google'      => '0.06',
        'Mapquest'    => '0.04',
        'Multimap'    => '0.01',
        'OSM'         => '0.01',
        'PlaceFinder' => '0.02',
        'Yahoo'       => '0.45',
    );
    while (my ($geocoder, $min_version) = each %geocoder_min_versions) {
        my $ref = 'Geo::Coder::' . $geocoder;

        eval ( "use $ref" );

        unless ($@) {
            $rh_requires->{$ref} = $min_version;
        }
    }
}

my $builder = Module::Build->new(
    module_name         => 'Geo::Coder::Many',
    license             => 'perl',
    dist_author         => q{Dan Horgan <cpan@lokku.com>},
    dist_version_from   => 'lib/Geo/Coder/Many.pm',
    requires            => $rh_requires,
    build_requires => {
        'Test::More' => 0,
        'Test::Exception' => 0,
        'Test::MockObject' => 0,
        'Test::Pod::Coverage' => 0,
    },
    add_to_cleanup      => [ 'Geo-Coder-Many-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

