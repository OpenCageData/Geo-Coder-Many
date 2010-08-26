package Geo::Coder::Many::Util;

use strict;
use warnings;
use List::Util qw( reduce );
use List::MoreUtils qw( any );

our @EXPORT_OK = qw( 
    min_precision_filter 
    max_precision_picker 
    consensus_picker 
    country_filter 
);
use Exporter;
use base qw(Exporter);

=head1 NAME

Geo::Coder::Many::Util

=head1 DESCRIPTION

Miscellaneous routines that are convenient for, for example, generating
commonly used callback methods to be used with Geo::Coder::Many.

=head1 SUBROUTINES

=head2 min_precision_filter

Constructs a result filter callback which only passes results which exceed the
specified precision.

=cut

sub min_precision_filter {
    my $precision_cutoff = shift;
    return sub {
        my $result = shift;
        if ( !defined $result->{precision} ) {
            return 0;
        }
        return $result->{precision} >= $precision_cutoff;
    }
}

=head2 country_filter

Constructs a result filter callback which only passes results with the
specified 'country' value.

=cut

sub country_filter {
    my $country_name = shift;
    return sub {
        my $result = shift;
        if ( !exists $result->{country} ) {
            return 0;
        }
        return $result->{country} eq $country_name;
    }
}

=head2 max_precision_picker

A picker callback that requests all available results, and then picks the one
with the highest precision. Note that querying all available geocoders may take
a comparatively long time.

Example:

$geo_multiple->set_picker_callback( \&max_precision_picker );

=cut

sub max_precision_picker {
    my ($ra_results, $more_available) = @_;

    # If more results are available, request them
    return if $more_available;

    # If we have all of the results, find the best
    return &_find_max_precision($ra_results);
}

=head2 consensus_picker 

Returns a picker callback that requires at least 'required_consensus' separate
geocoder results to be within a bounding square of side-length 'nearness'. If
this can be satisfied, the result from that square which has the highest
precision will be returned. Otherwise, asks for more/returns undef. 

WARNING: quadratic time in length of @$ra_results - could be improved if
necessary.

Example:

$geo_multiple->set_picker_callback( 
    consensus_picker({nearness => 0.1, required_consensus => 2})
);

=cut

sub consensus_picker {
    my $rh_args = shift;
    my $nearness = $rh_args->{nearness};
    my $required_consensus = $rh_args->{required_consensus};
    return sub {
        my $ra_results = shift;

        for my $result_a (@{$ra_results}) {

            my $lat_a = $result_a->{latitude};
            my $lon_a = $result_a->{longitude};

            # Find all of the other results that are close to this one
            my @consensus = grep { 
                _in_box( 
                    $lat_a, 
                    $lon_a, 
                    $nearness, 
                    $_->{latitude}, 
                    $_->{longitude} 
                ) 
            } @$ra_results;

            if ($required_consensus <= @consensus) {
                # If the consensus is sufficiently large, return the result
                # with the highest precision
                return _find_max_precision(\@consensus);
            }

        }

        # No consensus reached
        return;
    };
}

=head1 INTERNAL ROUTINES

=head2 _in_box

Used by consensus_picker - returns true iff ($lat, $lon) is inside the square
with centre ($centre_lat, $centre_lon) and side length 2*$half_width.

=cut

sub _in_box {
    my ($centre_lat, $centre_lon, $half_width, $lat, $lon) = @_;

    return $centre_lat - $half_width < $lat
        && $centre_lat + $half_width > $lat
        && $centre_lon - $half_width < $lon
        && $centre_lon + $half_width > $lon;
}

=head2 _find_max_precision

Given a reference to an array of result hashes, returns the one with the
highest precision value

=cut

sub _find_max_precision {
    my $ra_results = shift;
    return reduce {
        ($a->{precision} || 0.0) > ($b->{precision} || 0.0) ? $a : $b 
    } @{$ra_results};
}

1;
