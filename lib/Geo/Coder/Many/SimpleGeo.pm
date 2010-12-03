package Geo::Coder::Many::SimpleGeo;

use warnings;
use strict;
use Carp;
use base 'Geo::Coder::Many::Generic';

=head1 NAME

Geo::Coder::Many::SimpleGeo - SimpleGeo plugin Geo::Coder::Many

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module adds SimpleGeo support to Geo::Coder::Many.

Use as follows:

    use Geo::Coder::Many;
    use Geo::Coder::SimpleGeo;
    
    my $options = { };
    my $geocoder_many = Geo::Coder::Many->new( $options );
    my $SG = Geo::Coder::SimpleGeo->new(
                 #debug  => 1,
                 key    => 'Your Key',
                 secret => 'Your Secret',
             );
    
    my $options = {
        geocoder    => $SG,
    };
    
    $geocoder_many->add_geocoder( $options );
    
    my $location = $geocoder_many->geocode( 
        {
            location => '82 Clerkenwell Road, London, EC1M 5RF'
        }
    );

=head1 MORE INFO

please see http://search.cpan.org/dist/Geo-Coder-SimpleGeo/ 
and http://simplegeo.com/docs/

=head1 SUBROUTINES/METHODS

=head2 geocode

This is called by Geo::Coder::Many - it sends the geocoding request (via
Geo::Coder::SimpleGeo) and extracts the resulting location, returning it in a
standard Geo::Coder::Many::Response.

NOTE: unclear to me what the SimpleGeo precision field means, and I'm
thus unable to convert it into a meaningful number. Currently response
is thus undef. Also, SimpleGeo does not return the country, thus that
key's value is undef. Hopefully both of these can be addressed in
future versions.

=cut

sub geocode {
    my $self     = shift;
    my $location = shift;
    defined $location or croak "Geo::Coder::Many::SimpleGeo::geocode 
                                method must be given a location.";

    my @raw_replies = $self->{GeoCoder}->geocode( location => $location );
    my $response = Geo::Coder::Many::Response->new( { location => $location } );

    foreach my $raw_reply ( @raw_replies ) {

        my $lng = undef;
        my $lat = undef;
        if (defined($raw_reply->{geometry}{type})
            && $raw_reply->{geometry}{type} eq 'Point'){

	    my @coords = $raw_reply->{geometry}{coordinates};
            $lng = $coords[0];
            $lat = $coords[1];
	}
        # TODO - find a way to deal with polygons

        if (defined($lng) && defined($lat)){  # did we get anything?
            my $precision = $self->_determine_precision($raw_reply);
	    my $tmp = {
		address     => $raw_reply->{display_name},
		country     => undef,  # dont get this w/ SimpleGeo
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
sub _deteremine_precision {
    my $self = shift;
    my $raw  = shift;

    my $precision = undef;
    if (defined($raw->{properties}{precision})){
	my $sg_precision = $raw->{properties}{precision};
        # need to magically convert from simplegeo precision to 
        # number we can use, but can't find any docs
        # so for now we will do nothing :(
    }
    return $precision;
}

=head2 get_name

Returns the name of the geocoder type - used by Geo::Coder::Many

=cut

sub get_name { return 'simplegeo'; }

1; 

__END__
