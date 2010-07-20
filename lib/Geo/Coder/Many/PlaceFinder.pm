package Geo::Coder::Many::PlaceFinder;

use warnings;
use strict;
use Carp;

use Geo::Coder::Many::Generic;
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
    use Geo::Coder::Many::PlaceFinder;
    
    my $options = { };
    my $geocoder_multi = Geo::Coder::Many->new( $options );
    my $place_finder = Geo::Coder::PlaceFinder->new( appid => 'YOUR_APP_ID' );
    
    my $place_finder_options = {
        geocoder    => $place_finder,
        daily_limit => 50000,
    };
    
    $geocoder_multi->add_geocoder( $place_finder_options );
    
    my $location = $geocoder_multi->geocode( { location => '82 Clerkenwell Road, London, EC1M 5RF' } );

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
        
        @address_lines = grep {!/^\s*$/} @address_lines;
        my $address = (join ', ', @address_lines);

        my $tmp = {
              address     => $address,
              country     => $raw_reply->{country},
              longitude   => $raw_reply->{longitude},
              latitude    => $raw_reply->{latitude},
              precision   => $raw_reply->{quality} / 100,
        };

        $response->add_response( $tmp, $self->get_name() );
    };

    $response->set_response_code($http_response->code());

    return( $response );
};

=head2 get_name

Returns the name of the geocoder type - used by Geo::Coder::Many

=cut

sub get_name { return 'place_finder' };

=head1 AUTHOR

Dan Horgan, C<< <cpan at lokku.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-geo-coder-multiple-placefinder at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Coder-Many-PlaceFinder>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::Many::PlaceFinder


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-Many-PlaceFinder>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Coder-Many-PlaceFinder>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Coder-Many-PlaceFinder>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Coder-Many-PlaceFinder/>

=back


=head1 ACKNOWLEDGEMENTS

This module is based on the Geo::Coder::Many::* modules provided with Geo::Coder::Many.
It is, of course, useless without Geo::Coder::Many and Geo::Coder::PlaceFinder.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Lokku Ltd.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Geo::Coder::Many::PlaceFinder
