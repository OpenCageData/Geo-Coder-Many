
=head1 NAME

geo-coder-many.t

=head2 DESCRIPTION

General tests of Geo::Coder::Many

=cut

use strict;
use warnings;

use Test::More tests => 856;
use Test::MockObject;
use Test::Exception;
use Geo::Coder::Many;
use Geo::Coder::Many::Response;
use Geo::Coder::Many::Util;

use Geo::Coder::Bing;
use Geo::Coder::Google;
use Geo::Coder::Multimap;
use Geo::Coder::OSM;
use Geo::Coder::PlaceFinder;
use Geo::Coder::Yahoo;

# Picker callback for testing - only accepts a result if there are more available, always asks for more
sub _fussy_picker {
    my ($ra_results, $more_available) = @_;
    if ($more_available) {
        return;
    } else {
        return $ra_results->[0];
    }
}

sub general_test {
    my ($geo_multiple, $location) = @_;

    my $freqs = {};
    my $i = 0;
    my $trials = 10;
    while ($i < $trials) {
        my $result = $geo_multiple->geocode( { location => $location, wait_for_retries => 1 } );
        if (!defined $result) {
            $result->{geocoder} = "Could not geocode.";
        } else {
            if (defined $freqs->{$result->{geocoder}}) {
                $freqs->{$result->{geocoder}}++;
            } else {
                $freqs->{$result->{geocoder}} = 1;
            }
        }
        ++$i;
        print $i.": ". $result->{geocoder}." | ".($result->{address}||'[ No address found ]')."\n\n";
    }

    while (my ($geocoder, $freq) = each %$freqs) {
        print "$geocoder: $freq\n";
    }
}

=head2 dump_each

This prints out the response objects returned from each of the geocoders (via
Geo::Coder::Many::*) applied to the given location, for easier comparison.


sub dump_each {
    my ($geo_multi, $location) = @_;
    my $ra_coders = $geo_multi->_get_geocoders();
    for my $geo (@{$ra_coders}) {

        print $geo->get_name(), "\n";
        print Dumper($geo->geocode($location));
        print "\n---\n";
    }
}
=cut

# Use Test::MockObject to create a fake geocoder
sub fake_geocoder {
    my ($mock_number, $geocode_sub) = @_;

    my $geo_multi_mock = Test::MockObject->new;
    $geo_multi_mock->mock('get_daily_limit', sub { return 5000; });
    $geo_multi_mock->mock('geocode',
        sub {
            my ($self, $location) = @_;
            my $response = Geo::Coder::Many::Response->new( { location => $location } );
            my $use_results = &$geocode_sub;
            my $http_response = HTTP::Response->new($use_results->{code});
            $response->add_response( $use_results->{result}, $self->get_name() );
            $response->set_response_code($http_response->code());
            return $response;
        });
    $geo_multi_mock->mock('get_name', sub { return "mock$mock_number"; });

    my $ref_name_multi = "Geo::Coder::Many::Mock$mock_number";

    $geo_multi_mock->fake_module( $ref_name_multi );
    $geo_multi_mock->fake_new( $ref_name_multi );

    my $ref_name = "Geo::Coder::Mock$mock_number";

    my $geo_mock = Test::MockObject->new;
    $geo_mock->fake_module( $ref_name );

    # Bless the mock so that it has the correct ref...
    $geo_mock = bless {}, $ref_name;
    return $geo_mock;
}

# Produces a geocode result that is either successful or a failure at random.
sub random_fail {
    my $result = {
        address     => 'Address line1, line2, line3, etc',
        country     => 'United Kingdom',
        precision   => 0.6,
    };
    my $code;
    if ( rand() < 0.5 ) {
        $result->{longitude} = 0.0;
        $result->{latitude}  = 0.0;
        $code                = 400;
    }
    else {
        $result->{longitude} = -1.0;
        $result->{latitude}  = -1.0;
        $code                = 200;
    }
    return { result => $result, code => $code };
}

sub setup_geocoder {
    my $args = shift;

    my $geo_many = Geo::Coder::Many->new({ scheduler_type => $args->{scheduler_type}, use_timeouts => $args->{use_timeouts}});

    for my $gc (@{$args->{geocoders}}) {
        lives_ok ( sub { $geo_many->add_geocoder($gc) }, "Add ". ref($gc->{geocoder}));
    }

    $geo_many->set_filter_callback($args->{filter});
    $geo_many->set_picker_callback($args->{picker});



    return $geo_many;
}

sub create_geocoders {
    my $geo_bing = Geo::Coder::Bing->new(
        key => 'AkIBrsh38kFs_u2fiwaeQ2e99qtNAiPZj14QybpW1lJ8K4mXmK6pAW5P-qhyPZxe'
    );
    ok (defined $geo_bing, 'Create Bing geocoder');

    my $geo_mock0 = fake_geocoder( 0, \&random_fail );
    my $geo_mock1 = fake_geocoder( 1, \&random_fail );
    ok (defined $geo_mock0 && defined $geo_mock1, 'Create mock geocoders');

    my $geo_google = Geo::Coder::Google->new( 
        apikey => 'ABQIAAAALLo4z01QoBSfUJHs2ewllxT2yXp_ZAY8_ufC3CFXhHIE1NvwkxSPGFXdqPR-e_JO9AvMcX8OwL8FOw'
    );
    ok (defined $geo_google, 'Create Google geocoder');

    my $geo_multimap = Geo::Coder::Multimap->new(
        apikey => 'OA10071514643171291'
    );
    ok (defined $geo_multimap, 'Create Multimap geocoder');

    my $geo_osm   = Geo::Coder::OSM->new;
    ok (defined $geo_osm, 'Create OSM geocoder');

    my $geo_yahoo = Geo::Coder::Yahoo->new(
        appid => 'XdC5vtPV34GOl4zXHo4yy2OPT6ldCNRekMNlByqDAm8ksDooa6iJd0bsUnzwUds'
    );
    ok (defined $geo_yahoo, 'Create Yahoo geocoder');

    my $geo_placefinder = Geo::Coder::PlaceFinder->new(
        appid => 'tFESRf4a'
    );
    ok (defined $geo_placefinder, 'Create PlaceFinder geocoder');

    my @geocoders = (
        { geocoder => $geo_mock0,       daily_limit => 10000 },
        { geocoder => $geo_mock1,       daily_limit => 10000 },
        { geocoder => $geo_bing,        daily_limit => 200 },
        { geocoder => $geo_google,      daily_limit => 400 },
        { geocoder => $geo_multimap,    daily_limit => 500 },
        { geocoder => $geo_osm,         daily_limit => 600 },
        { geocoder => $geo_yahoo,       daily_limit => 700 },
        { geocoder => $geo_placefinder, daily_limit => 800 },
    );

    return @geocoders;
}

# Thorough test of all combinations of options
{
    my $location = '82, Clerkenwell Road, London';

    my @filter_callbacks = (
        '',
        'all',
        sub { return 0; },
        sub { return 1; },
        sub { return rand() < 0.5; },
        country_filter ( 'United Kingdom' ),
        min_precision_filter ( 0.3 ),
    );

    my @picker_callbacks = (
        '',
        'max_precision',
        \&_fussy_picker,
        sub { return ; },
        consensus_picker ({ required_consensus => 2, nearness => 0.1 }),
    );

    my @schedulers = (
        'WRR',
        'OrderedList',
        'WeightedRandom',
    );



    my @geocoders = create_geocoders();
    #my $geo = &setup_geocoder({ filter => 'all', picker => '', scheduler_type => 'WRR', use_timeouts => 1});

    #use Cache::MemoryCache;
    #my $cache_object = new Cache::MemoryCache( { 'namespace' => 'Geo::Coder::Many',
    #                                             'default_expires_in' => 600 } );

    my @mock_geocoders = grep { ref($_->{geocoder}) =~ /Mock/ } @geocoders;

    for my $filter (@filter_callbacks) {
        for my $picker (@picker_callbacks) {
            for my $scheduler (@schedulers) {
                for my $timeouts ((0, 1)) {
                    my $geo;
                    lives_and { 
                        $geo = &setup_geocoder({
                                filter => $filter,
                                picker => $picker,
                                scheduler_type => $scheduler,
                                use_timeouts => $timeouts,
                                geocoders => \@mock_geocoders
                            });
                        ok (defined $geo);
                    } "Geo::Coder::Many with filter $filter, picker $picker, scheduler $scheduler, timeouts $timeouts";
                    lives_ok {
                        for (1 .. 10) {
                            my $result = $geo->geocode({location => $location});
                        }
                    } "Test geocoding...\n";
                }
            }
        }
    }

    #&dump_each($geo_many, $location);
    lives_ok {
        my $geo_many = &setup_geocoder({ filter => 'all', picker => '', scheduler_type => 'WRR', use_timeouts => 1, geocoders => \@geocoders});
        &general_test($geo_many, $location);
    } "Test actual geocoders";
}


1;
__END__
