package Geo::Coder::Many::OSM;

use warnings;
use strict;
use Carp;

use Geo::Coder::Many::Generic;
use base 'Geo::Coder::Many::Generic';

=head1 NAME

Geo::Coder::Many::OSM - OpenStreetMap Nominatim plugin for Geo::Coder::Many

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module adds OpenStreetMap Nominatim support to Geo::Coder::Many.

Use as follows:

    use Geo::Coder::Many;
    use Geo::Coder::OSM;
    use Geo::Coder::Many::OSM;
    
    my $options = { };
    my $geocoder_multi = Geo::Coder::Many->new( $options );
    my $osm = Geo::Coder::OSM->new;
    
    my $osm_options = {
        geocoder    => $osm,
    # This limit should not be taken as necessarily valid. Check the Nominatim
    # usage policy.
        daily_limit => 5000,
    };
    
    $geocoder_multi->add_geocoder( $osm_options );
    
    my $location = $geocoder_multi->geocode( 
        {
            location => '82 Clerkenwell Road, London, EC1M 5RF'
        }
    );

=head1 USAGE POLICY

Be careful to limit the number of requests you send, or risk being blocked.

See http://wiki.openstreetmap.org/wiki/Nominatim#Usage_Policy for details.

=head1 SUBROUTINES/METHODS

=head2 geocode

This is called by Geo::Coder::Many - it sends the geocoding request (via
Geo::Coder::OSM) and extracts the resulting location, returning it in a
standard Geo::Coder::Many::Response.

=cut

sub geocode {
    my $self     = shift;
    my $location = shift;
    defined $location or croak "Geo::Coder::Many::OSM::geocode 
                                method must be given a location.";

    my @raw_replies = $self->{GeoCoder}->geocode( location => $location );
    my $response = Geo::Coder::Many::Response->new( { location => $location } );

    my $location_data = [];

    foreach my $raw_reply ( @raw_replies ) {
        my $tmp = {
              address     => $raw_reply->{display_name},
              country     => $raw_reply->{address}{country},
              longitude   => $raw_reply->{lon},
              latitude    => $raw_reply->{lat},
              precision   => undef, # Precision info is not given... (?)
        };

        $response->add_response( $tmp, $self->get_name() );
    };

    my $http_response = $self->{GeoCoder}->response();
    $response->set_response_code($http_response->code());

    return $response;
};

=head2 get_name

Returns the name of the geocoder type - used by Geo::Coder::Many

=cut

sub get_name { 
    return 'osm';
}

=head1 AUTHOR

Dan Horgan, C<< <cpan at lokku.com> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-geo-coder-multiple-osm at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Coder-Many-OSM>.  I will
be notified, and then you'll automatically be notified of progress on your bug
as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::Many::OSM


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-Many-OSM>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Coder-Many-OSM>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Coder-Many-OSM>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Coder-Many-OSM/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Lokku Ltd.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Geo::Coder::Many::OSM
