package Geo::Coder::Many::Response;

use strict;
use warnings;

=head1 NAME

=head1 DESCRIPTION

=head1 METHODS

=head2 new

Constructs and returns a new, empty response object.

=cut

sub new {
    my $class = shift;
    my $args = shift;

    my $self = {
        location        => $args->{location},
        responses       => [],
        response_code   => 401,
        geocoder        => undef,
    };

    bless $self, $class;

    return( $self );
};

=head2 add_response

Takes a response, together with the name of the geocoder used to produce it, and stores it.

=cut

sub add_response {
    my $self = shift;
    my $response = shift;
    my $geocoder = shift;

    $self->{geocoder} = $geocoder;

    if( $response->{longitude} && $response->{latitude} ) {
        push @{$self->{responses}}, $response;
        $self->{response_code} = 200;
    }
    else { return( 0 ) };

    return( 1 );
};

=head2 set_response_code

=cut

sub set_response_code {
    my $self = shift;
    my $response_code = shift;
    $self->{response_code} = $response_code;

    return $response_code;
}

=head2 get_location
    
Getter for the location string

=cut

sub get_location { return( $_[0]->{location} ) };

=head2 get_response_code

Getter for the response code

=cut

sub get_response_code { return( $_[0]->{response_code} ) };

=head2 get_geocoder

Getter for the geocoder name

=cut

sub get_geocoder { return( $_[0]->{geocoder} ) };

=head2 get_responses

In list context, returns all of the responses. In scalar context, returns the
first response.

=cut

sub get_responses {
    my $self = shift;

    return wantarray ? @{$self->{responses}} : $self->{responses}->[0];
};


1;
