#!/usr/bin/env perl
use inc::Module::Install;

# name "";
# all_from "lib/";
repository "git://github.com/pangyre/p5-cat-starman-daemon";

requires "Catalyst::Runtime" => "5.80007";
requires "Starman";

#test_requires "Test::WWW::Mechanize::Catalyst";

catalyst;

if ( $Module::Install::AUTHOR )
{
}

#Create dirs qw( etc var...? )

#install_script glob("script/*.pl");

auto_install;

WriteAll;

__END__

