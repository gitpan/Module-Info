#!/usr/bin/perl -w

use lib qw(t/lib);
use Test::More tests => 68;
use Config;

my $Mod_Info_VERSION = 0.07;

use_ok('Module::Info');
can_ok('Module::Info', qw(new_from_file new_from_module all_installed
                          name version inc_dir file is_core
                          packages_inside modules_used
                         ));

my $mod_info = Module::Info->new_from_file('lib/Module/Info.pm');
isa_ok($mod_info, 'Module::Info', 'new_from_file');

ok( !$mod_info->name,                       '    has no name' );
is( $mod_info->version, $Mod_Info_VERSION,  '    version()' );
ok( !$mod_info->inc_dir,                    '    has no inc_dir' );
is( $mod_info->file, File::Spec->rel2abs('lib/Module/Info.pm'),
                                            '    file()');
ok( !$mod_info->is_core,                    '    not a core module' );

SKIP: {
    skip "Only works on 5.6.1 and up.", 30 unless $] >= 5.006001;

    my %expected_subs = (
                         new_from_file          => [63,  73],
                         new_from_module        => [90,  91],
                         new_from_loaded        => [104, 114],
                         all_installed          => [129, 130],
                         _find_all_installed    => [135, 156],
                         name                   => [179, 180],
                         version                => [194, 224],
                         inc_dir                => [238, 240],
                         file                   => [252, 254],
                         is_core                => [270, 272],
                         packages_inside        => [304, 317],
                         modules_used           => [333, 341],
                         subroutines            => [378, 386],
                        );
    %expected_subs = map { ("Module::Info::$_" => $expected_subs{$_}) } 
                     keys %expected_subs;

    my @packages = $mod_info->packages_inside;
    is( @packages, 1,                   'Found a single package inside' );
    is( $packages[0], 'Module::Info',   '  and its what we want' );

    my %subs = $mod_info->subroutines;
    is( keys %subs, keys %expected_subs,    'Found all the subroutines' );
    is_deeply( [sort keys %subs], 
               [sort keys %expected_subs],  '   names' );
    
    while( my($name, $info) = each %expected_subs ) {
        is( $expected_subs{$name}[0], $subs{$name}{start},  "$name start" );
        is( $expected_subs{$name}[1], $subs{$name}{end},    "$name end" );
    }
}


$mod_info = Module::Info->new_from_module('Module::Info');
isa_ok($mod_info, 'Module::Info', 'new_from_module');

is( $mod_info->name, 'Module::Info',        '    name()' );
is( $mod_info->version, $Mod_Info_VERSION,  '    version()' );
is( $mod_info->inc_dir, File::Spec->rel2abs('blib/lib'),
                                            '    inc_dir' );
is( $mod_info->file, File::Spec->rel2abs('blib/lib/Module/Info.pm'),
                                            '    file()');
ok( !$mod_info->is_core,                    '    not a core module' );


# Grab the core version of Text::Soundex and hope it hasn't been
# deleted.
@core_inc = ($Config{installarchlib}, $Config{installprivlib});
$mod_info = Module::Info->new_from_module('Text::Soundex', @core_inc);
is( $mod_info->name, 'Text::Soundex',       '    name()' );

# dunno what the version will be, 5.004's had none.

ok( grep($mod_info->inc_dir eq $_, @core_inc),       '    inc_dir()' );
is( $mod_info->file, 
    File::Spec->catfile( $mod_info->inc_dir, 'Text', 'Soundex.pm' ),
                                            '    file()');
ok( $mod_info->is_core,                     '    core module' );


$mod_info = Module::Info->new_from_loaded('Module::Info');
isa_ok($mod_info, 'Module::Info', 'new_from_module');

is( $mod_info->name, 'Module::Info',        '    name()' );
is( $mod_info->version, $Mod_Info_VERSION,  '    version()' );
is( $mod_info->inc_dir, File::Spec->rel2abs('blib/lib'),
                                            '    inc_dir' );
is( $mod_info->file, File::Spec->rel2abs('blib/lib/Module/Info.pm'),
                                            '    file()');
ok( !$mod_info->is_core,                    '    not a core module' );


@modules = Module::Info->all_installed('Module::Info');
ok( @modules,       'all_installed() returned something' );
ok( !(grep { !defined $_ || !$_->isa('Module::Info') } @modules),
                    "  they're all Module::Info objects"
  );

# I have no idea how many I'm going to get, so I'll only play with the 
# first one.  It's the current one.
$mod_info = $modules[0];
isa_ok($mod_info, 'Module::Info', 'all_installed');

is( $mod_info->name, 'Module::Info',        '    name()' );
is( $mod_info->version, $Mod_Info_VERSION,  '    version()' );
ok( !$mod_info->is_core,                    '    not a core module' );


# Ensure that code refs in @INC are skipped.
my @mods = Module::Info->all_installed('Module::Info', (@INC, sub { die }));
ok( @modules,       'all_installed() returned something' );
ok( !(grep { !defined $_ || !$_->isa('Module::Info') } @modules),
                    "  they're all Module::Info objects"
  );


SKIP: {
    skip "Only works on 5.6.1 and up.", 6 unless $] >= 5.006001;

    my $module = Module::Info->new_from_file('t/lib/Foo.pm');
    my @packages = $module->packages_inside;
    is( @packages, 2,       'Found two packages inside' );
    ok( eq_set(\@packages, [qw(Foo Bar)]),   "  they're right" );

    my %subs = $module->subroutines;
    is( keys %subs, 1,                          'Found one subroutine' );
    ok( exists $subs{'Foo::wibble'},            '   its right' );

    my($start, $end) = @{$subs{'Foo::wibble'}}{qw(start end)};
    print "# start $start, end $end\n";
    is( $start, 13,           '   start line' );
    is( $end,   14,           '   end line'   );
}
