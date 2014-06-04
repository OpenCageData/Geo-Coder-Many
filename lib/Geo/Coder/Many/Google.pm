package Geo::Coder::Many::Google;

use strict;
use warnings;
use Carp;
use Geo::Coder::Many::Util;
use base 'Geo::Coder::Many::Generic';

=head1 NAME

Geo::Coder::Many::Google - Plugin for the google maps geocoder

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

# Requires Geo::Coder::Google 0.06 or above
sub _MIN_MODULE_VERSION { return '0.06'; }


=head1 SYNOPSIS

This class wraps Geo::Coder::Google such that it can be used in
Geo::Coder::Many, by converting the results to a standard form.

Note: Geo::Coder::Google uses the deprecated version 2 of the Google
geocoder. There is a newer Geo::Coder::Googlev3 (also supported by
Geo::Coder::Many). 

=head1 METHODS

=head2 geocode

Takes a location string, geocodes it using Geo::Coder::Google, and returns the
result in a form understandable to Geo::Coder::Many

=cut

# see details of google's response format here:
# v2: http://code.google.com/apis/maps/documentation/javascript/v2/services.html#Geocoding
# v3: http://code.google.com/apis/maps/documentation/geocoding/

sub geocode {
    my $self = shift;
    my $location = shift;
    defined $location or croak "Geo::Coder::Many::Google::geocode 
                                method must be given a location.";

    my @raw_replies = $self->{GeoCoder}->geocode( $location );

    my $Response = Geo::Coder::Many::Response->new( { location => $location } );

    foreach my $raw_reply ( @raw_replies ) {

        my $precision = 0; # unknown

        if (defined($raw_reply->{ExtendedData}) 
            && defined($raw_reply->{ExtendedData}{LatLonBox}) ){

            my $box = $raw_reply->{ExtendedData}{LatLonBox};
            # lng and lat in decimal degree format            

            $precision = 
		Geo::Coder::Many::Util::determine_precision_from_bbox({
                    'lon1' => $box->{south},
                    'lat1' => $box->{west},
                    'lon2' => $box->{north},
                    'lat2' => $box->{east},
                });
	}

        my $tmp = {
            address   => $raw_reply->{address},
            country   => $raw_reply->{AddressDetails}{Country}{CountryNameCode},
            latitude  => $raw_reply->{Point}{coordinates}[1],
            longitude => $raw_reply->{Point}{coordinates}[0],
            precision => $precision,
        };
        $Response->add_response( $tmp, $self->get_name());
    }
    return $Response;
}

=head2 get_name

The short name by which Geo::Coder::Many can refer to this geocoder.

=cut

sub get_name { my $self = shift; return 'google ' . $self->{GeoCoder}->VERSION; }

1;
