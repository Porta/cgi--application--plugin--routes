#! /usr/bin/perl -w
use strict;
use CGI::Carp qw(fatalsToBrowser);
use TestApp;


open(STDERR, '>>logfile');

my $app = TestApp->new;
$app->run;

__END__