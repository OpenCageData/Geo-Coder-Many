use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Geo::Coder::Many',
    license             => 'perl',
    dist_author         => q{Dan Horgan <cpan@lokku.com>},
    dist_version_from   => 'lib/Geo/Coder/Many.pm',
    requires            => {
        'perl'          => '5.010',
        'List::Util::WeightedRoundRobin' => '0.4',
        'List::Util' => '1.23',
        'List::MoreUtils' => '0.22',
    },
    build_requires => {
        'Test::More' => 0,
        'Test::MockObject' => 0,
        'Test::Pod::Coverage' => 0,
        
    },
    add_to_cleanup      => [ 'Geo-Coder-Many-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

