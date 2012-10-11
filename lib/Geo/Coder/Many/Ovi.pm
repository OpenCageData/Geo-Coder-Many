package Geo::Coder::Many::Ovi;

use warnings;
use strict;
use Carp;
use Geo::Coder::Many::Util;
use base 'Geo::Coder::Many::Generic';

=head1 NAME

Geo::Coder::Many::Ovi - Ovi plugin Geo::Coder::Many

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

# Requires Geo::Coder::Ovi 0.01 or above
sub _MIN_MODULE_VERSION { return '0.01'; }

=head1 SYNOPSIS

This module adds Ovi support to Geo::Coder::Many.

Use as follows:

    use Geo::Coder::Many;
    use Geo::Coder::Ovi;
    
    my $options = { };
    my $geocoder_many = Geo::Coder::Many->new( $options );
    my $GCO = Geo::Coder::Ovi->new();
    
    my $options = {
        geocoder    => $GCO,
    };
    
    $geocoder_many->add_geocoder( $options );
    
    my $location = $geocoder_many->geocode( 
        {
            location => 'London EC1M 5RF, United Kingdom'
        }
    );

=head1 MORE INFO

please see http://search.cpan.org/dist/Geo-Coder-Ovi/ 

=head1 SUBROUTINES/METHODS

=head2 geocode

This is called by Geo::Coder::Many - it sends the geocoding request (via
Geo::Coder::Ovi) and extracts the resulting location, returning it in a
standard Geo::Coder::Many::Response.

Note: the precision score is set based on the size of the bounding box returned.
Not all queries seem to return a bounding box. In that case precision in undef

=cut

sub geocode {
    my $self     = shift;
    my $location = shift;
    defined $location or croak "Geo::Coder::Many::Ovi::geocode 
                                method must be given a location.";

    my @raw_replies = $self->{GeoCoder}->geocode( location => $location );
    my $response = Geo::Coder::Many::Response->new( { location => $location } );

    foreach my $raw_reply ( @raw_replies ) {

        my $lng = undef;
        my $lat = undef;
        if (defined($raw_reply->{properties})){
            $lat = $raw_reply->{properties}{geoLatitude};
            $lng = $raw_reply->{properties}{geoLongitude};
	}

        if (defined($lng) && defined($lat)){  # did we get anything?
            my $precision = $self->_determine_precision($raw_reply);
	    my $tmp = {
		address     => $raw_reply->{title},
		country     => $raw_reply->{addrCountryName},
		longitude   => $lng,
		latitude    => $lat,
		precision   => $precision,
	    };
	    $response->add_response( $tmp, $self->get_name() );
	}
    }

    my $http_response = $self->{GeoCoder}->response();
    $response->set_response_code($http_response->code());
    return $response;
}

# return number between 0 and 1
sub _determine_precision {
    my $self = shift;
    my $raw  = shift;

    my $precision = undef;
    # if we have a bounding box we can calculate a precision
    if (defined($raw->{properties})
        && defined($raw->{properties}{geoBbxLatitude2})
       ){

       $precision = 
                Geo::Coder::Many::Util::determine_precision_from_bbox({
                    'lon1' => $raw->{properties}{geoBbxLongitude1},
                    'lat1' => $raw->{properties}{geoBbxLatitude1},
                    'lon2' => $raw->{properties}{geoBbxLongitude2},
                    'lat2' => $raw->{properties}{geoBbxLatitude2},
                });
    }
    return $precision;
}

=head2 get_name

Returns the name of the geocoder type - used by Geo::Coder::Many

=cut

sub get_name { my $self = shift; return 'ovi ' . $self->{GeoCoder}->VERSION; }

1; 

__END__
