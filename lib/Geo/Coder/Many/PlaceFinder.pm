package Geo::Coder::Many::PlaceFinder;

use warnings;
use strict;
use Carp;

use Geo::Coder::Many::Generic;
use Geo::Coder::Many::Util;
use base 'Geo::Coder::Many::Generic';

=head1 NAME

Geo::Coder::Many::PlaceFinder - Yahoo PlaceFinder plugin for Geo::Coder::Many

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

This module adds Yahoo PlaceFinder support to Geo::Coder::Many.

Use as follows:

    use Geo::Coder::Many;
    use Geo::Coder::PlaceFinder;
    
    my $options = { };
    my $geocoder_many = Geo::Coder::Many->new( $options );
    my $place_finder = Geo::Coder::PlaceFinder->new( appid => 'YOUR_APP_ID' );
    
    my $place_finder_options = {
        geocoder    => $place_finder,
        daily_limit => 50000,
    };
    
    $geocoder_many->add_geocoder( $place_finder_options );
    
    my $location = $geocoder_many->geocode( 
        {
            location => '82 Clerkenwell Road, London, EC1M 5RF'
        }
    );

=head1 USAGE POLICY

As of writing, Yahoo PlaceFinder allows up to 50000 requests per day.  This may
change, so you should check the latest documentation to make sure you aren't
going to get blocked.

http://developer.yahoo.com/geo/placefinder/

=head1 SUBROUTINES/METHODS

=head2 geocode

This is called by Geo::Coder::Many - it sends the geocoding request (via
Geo::Coder::PlaceFinder) and extracts the resulting location, returning it in a
standard Geo::Coder::Many::Response.

=cut

sub geocode {
    my $self = shift;
    my $location = shift;
    defined $location or croak "geocode method must be given a location\n";

    my @raw_replies = $self->{GeoCoder}->geocode( location => $location );
    my $response = Geo::Coder::Many::Response->new( { location => $location } );

    my $http_response = $self->{GeoCoder}->response();
    my $location_data = [];

    foreach my $raw_reply ( @raw_replies ) {
        my @address_lines = @{$raw_reply}{'line1', 'line2', 'line3', 'line4'};
        
        @address_lines = grep {!/^\s*$/x} @address_lines;
        my $address = (join ', ', @address_lines);

	my $precision = 0;
	if (defined($raw_reply->{boundingbox})){
	    
	    my $box = $raw_reply->{boundingbox};
	    # lng and lat in decimal degree format            
	    
	    $precision = 
		Geo::Coder::Many::Util::determine_precision_from_bbox({
		    'lon1' => $box->{west},
		    'lat1' => $box->{south},
		    'lon2' => $box->{east},
		    'lat2' => $box->{north},
                });

	} 
        my $tmp = {
              address     => $address,
              country     => $raw_reply->{country},
              longitude   => $raw_reply->{longitude},
              latitude    => $raw_reply->{latitude},
              precision   => $precision,
        };

        $response->add_response( $tmp, $self->get_name() );
    }

    $response->set_response_code($http_response->code());
    return $response;
}

=head2 get_name

Returns the name of the geocoder type - used by Geo::Coder::Many

=cut

sub get_name { return 'place_finder' };

1; # End of Geo::Coder::Many::PlaceFinder
