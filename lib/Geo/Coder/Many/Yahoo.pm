package Geo::Coder::Many::Yahoo;

use strict;
use warnings;
use base 'Geo::Coder::Many::Generic';

=head1 NAME

Geo::Coder::Many::Yahoo

=head1 SYNOPSIS

This class wraps Geo::Coder::Yahoo such that it can be used in
Geo::Coder::Many, by converting the results to a standard form.

Note - Yahoo! says this geocoding service is deprecated and that
you should instead be using Geo::Coder::Placefinder.

=head1 METHODS

=head2 geocode

Takes a location string, geocodes it using Geo::Coder::Yahoo, and returns the
result in a form understandable to Geo::Coder::Many

=cut

sub geocode {
    my $self = shift;
    my $location = shift;

    my $raw_replies = $self->{GeoCoder}->geocode( location => $location );

    my $Response = Geo::Coder::Many::Response->new( { location => $location } );

    my $location_data = [];

    my %precisions = (
        country => 0.1,
        state   => 0.2,
        city    => 0.4,
        zip     => 0.5,
        'zip+2' => 0.6,
        'zip+4' => 0.8,
        street  => 0.9,
        address => 1.0,
    );

    foreach my $raw_reply ( @{$raw_replies} ) {
        my $tmp = {
            address     => $raw_reply->{address},
            country     => $raw_reply->{country},
            longitude   => $raw_reply->{longitude},
            latitude    => $raw_reply->{latitude},
            precision   => $precisions{$raw_reply->{precision}},
        };

        $Response->add_response( $tmp, $self->get_name());
    };

    return $Response;
}

=head2 get_name

The short name by which Geo::Coder::Many can refer to this geocoder.

=cut

sub get_name { return 'yahoo'; }

1;

__END__
