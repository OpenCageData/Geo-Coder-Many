package Geo::Coder::Many::Google;

use strict;
use warnings;

use base 'Geo::Coder::Many::Generic';

=head1 NAME

Geo::Coder::Many::Google

=head1 SYNOPSIS

This class wraps Geo::Coder::Google such that it can be used in
Geo::Coder::Many, by converting the results to a standard form.

=head1 METHODS

=head2 geocode

Takes a location string, geocodes it using Geo::Coder::Google, and returns the
result in a form understandable to Geo::Coder::Many

=cut

sub geocode {
    my $self = shift;
    my $location = shift;

    my @raw_replies = $self->{GeoCoder}->geocode( $location );

    my $Response = Geo::Coder::Many::Response->new( { location => $location } );

    foreach my $raw_reply ( @raw_replies ) {
        my $tmp = {
            address     => $raw_reply->{address},
            country     => $raw_reply->{AddressDetails}->{Country}->{CountryNameCode},
            latitude    => $raw_reply->{Point}->{coordinates}->[1],
            longitude   => $raw_reply->{Point}->{coordinates}->[0],
            precision   => 1.0,
        };

        $Response->add_response( $tmp, $self->get_name());
    };

    return( $Response );
};

=head2 get_name

The short name by which Geo::Coder::Many can refer to this geocoder.

=cut

sub get_name { return 'google' };


1;

__END__

