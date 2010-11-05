package Geo::Coder::Many::Google;

use strict;
use warnings;
use Geo::Distance::XS; # for calculating precision
use base 'Geo::Coder::Many::Generic';


=head1 NAME

Geo::Coder::Many::Google - Plugin for the google maps geocoder

=head1 SYNOPSIS

This class wraps Geo::Coder::Google such that it can be used in
Geo::Coder::Many, by converting the results to a standard form.

=head1 METHODS

=head2 geocode

Takes a location string, geocodes it using Geo::Coder::Google, and returns the
result in a form understandable to Geo::Coder::Many

=cut

# see details of google's response format here:
# http://code.google.com/apis/maps/documentation/geocoding/

sub geocode {
    my $self = shift;
    my $location = shift;

    my $GDXS = Geo::Distance->new;

    my @raw_replies = $self->{GeoCoder}->geocode( $location );

    my $Response = Geo::Coder::Many::Response->new( { location => $location } );

    foreach my $raw_reply ( @raw_replies ) {

        # need to determine precision
        my $distance = 0;
        if (defined($raw_reply->{geometry}) 
            && defined($raw_reply->{geometry}{viewport}) ){

            # lng and lat in decimal degree format            
            my $sw_lon = $raw_reply->{geometry}{viewport}{southwest}{lng};
            my $sw_lat = $raw_reply->{geometry}{viewport}{southwest}{lat};
            my $ne_lon = $raw_reply->{geometry}{viewport}{northeast}{lng};
            my $ne_lat = $raw_reply->{geometry}{viewport}{northeast}{lat};

	    $distance = $GDXS->distance('kilometer', 
                                        $sw_lon, $sw_lat => $ne_lon, $ne_lat);
	}
        my $precision = $self->_determine_precision($distance);
        my $tmp = {
            address   => $raw_reply->{address},
            country   => $raw_reply->{AddressDetails}{Country}{CountryNameCode},
            latitude  => $raw_reply->{Point}{coordinates}[1],
            longitude => $raw_reply->{Point}{coordinates}[0],
            precision => $precision,
        };

        $Response->add_response( $tmp, $self->get_name());
    };

    return $Response;
}

# map distance in kilometers to a score between 0 and 1
sub _determine_precision {
    my $self = shift;
    my $distance = shift;  # in km

    return 0    if (!$distance);
    return 1.0  if ($distance < 0.25);
    return 0.9  if ($distance < 0.5);
    return 0.8  if ($distance < 1);
    return 0.7  if ($distance < 2);
    return 0.5  if ($distance < 5);
    return 0.3  if ($distance < 10);
    return 0.1;
}



=head2 get_name

The short name by which Geo::Coder::Many can refer to this geocoder.

=cut

sub get_name {
    return 'google';
}


1;

__END__
