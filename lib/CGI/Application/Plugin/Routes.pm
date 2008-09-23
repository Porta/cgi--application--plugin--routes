package CGI::Application::Plugin::Routes;
use strict;
use Carp;

use vars qw($VERSION @ISA @EXPORT);

our $VERSION = '0.01';

sub import {
    my $pkg     = shift;
    my $callpkg = caller;

    # Do our own exporting.
    {
        no strict qw(refs);
        *{ $callpkg . '::routes' } = \&CGI::Application::Plugin::Routes::routes;
        *{ $callpkg . '::routes_parse' } = \&CGI::Application::Plugin::Routes::routes_parse;
        *{ $callpkg . '::routes_dbg' } = \&CGI::Application::Plugin::Routes::routes_dbg;
        *{ $callpkg . '::routes_root' } = \&CGI::Application::Plugin::Routes::routes_root;
    }

    if ( ! UNIVERSAL::isa($callpkg, 'CGI::Application') ) {
        warn "Calling package is not a CGI::Application module so not setting up the prerun hook.  If you are using \@ISA instead of 'use base', make sure it is in a BEGIN { } block, and make sure these statements appear before the plugin is loaded";
    }
    elsif ( ! UNIVERSAL::can($callpkg, 'add_callback')) {
        warn "You are using an older version of CGI::Application that does not support callbacks, so the prerun method can not be registered automatically (Lookup the prerun_callback method in the docs for more info)";
    }
    else {
	    #Add the required callback to the CGI::Application app so it executes the routes_parse sub on the prerun stage
        $callpkg->add_callback( prerun => 'routes_parse' );
    }
}


sub routes {
	my ($self, $table) = @_;
	$self->{'Application::Plugin::Routes::__dispatch_table'} = $table;
}

sub routes_dbg {
	my $self = shift;
    require Data::Dumper;
	return Dumper($self->{'Application::Plugin::Routes::__r_params'});
}

sub routes_root{
	my ($self, $root) = @_;
	#make sure no trailing slash is present on the root.
	$root =~ s/\/$//;
	$self->{'Application::Plugin::Routes::__routes_root'} = $root;
}

sub routes_parse {
	#all this routine, except a few own modifications was borrowed from the wonderful
	# Michael Peter's CGI::Application::Dispatch module that can be found here:
	# http://search.cpan.org/~wonko/CGI-Application-Dispatch/
	my ($self) = @_;
	my $path = $self->query->path_info;
	# get the module name from the table
	my $table = $self->{'Application::Plugin::Routes::__dispatch_table'};
	unless(ref($table) eq 'ARRAY') {
		carp "[__parse_path] Invalid or no dispatch table!\n";
		return;
	}
	# look at each rule and stop when we get a match
	for(my $i = 0 ; $i < scalar(@$table) ; $i += 2) {
		my $rule = $self->{'Application::Plugin::Routes::__routes_root'} . $table->[$i];
		my @names = ();
		# translate the rule into a regular expression, but remember where the named args are
		# '/:foo' will become '/([^\/]*)'
		# and
		# '/:bar?' will become '/?([^\/]*)?'
		# and then remember which position it matches
		$rule =~ s{
						(^|/)                 # beginning or a /
						(:([^/\?]+)(\?)?)     # stuff in between
				}{
						push(@names, $3);
						$1 . ($4 ? '?([^/]*)?' : '([^/]*)')
				}gxe;
		# '/*/' will become '/(.*)/$' the end / is added to the end of
		# both $rule and $path elsewhere
		if($rule =~ m{/\*/$}) {
			$rule =~ s{/\*/$}{/(.*)/\$};
			push(@names, 'dispatch_url_remainder');
		}
		# if we found a match, then run with it
		if(my @values = ($path =~ m#^$rule$#)) {
			$self->{'Application::Plugin::Routes::__match'} = $path;
			my %named_args;
			$self->param('rm',$table->[++$i]);

            my $rm_name = $table->[$i];
			$self->prerun_mode($rm_name);

            # If the run mode corresponds to a method name and we don't already
            # a run mode registered by that name, then register one now.
            my %rms = $self->run_modes;
            if (not exists $rms{$rm_name} and $self->can($rm_name)) {
                $self->run_modes([$rm_name]);
            }

			@named_args{@names} = @values if @names;
			#force params into $self->query. NOTE that it will overwrite any existing param with the same name
			foreach my $k (keys %named_args){
				$self->query->param("$k", $named_args{$k});
			}
			$self->{'Application::Plugin::Routes::__r_params'} = {"parsed_params: " => \%named_args, "path_received: " => $path, "rule_matched: " => $rule, "runmode: " => $rm_name};
		}
	}
}

1;
__END__

=head1 NAME

CGI::Application::Plugin::Routes - CGI::Application::Plugin::Routes

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

CGI::Application::Plugin::Routes tries to bring to perl some of the goodies of Rails routes by allowing the creationg of a routes table that is parsed at the prerun stage again the CGI's path_info data. The result of the process (if there's any match at the end of the process) is added to CGI's query method from CGI::Application and available to all the runmodes via the CGI::Application::query::param method.
By doing this, the plugin provides a uniform way to access GET and POST parameters when using clean url's with the query->param() method.

Perhaps a little code snippet.

In TestApp.om

	package TestApp;
	use strict;
	use warnings;
	use base qw/CGI::Application/;
	use CGI::Application::Plugin::Routes;
	sub setup {
		my $self = shift;

		$self->routes_root('/thismod');#optional, will be used to prepend every route defines in $self->routes.
		$self->routes([
			'' => 'home' ,
			'/view/:name/:id/:email'  => 'view',
		]);
		$self->start_mode('show');

		$self->tmpl_path('templates/');
	}
	sub view {
		my $self = shift;
		my $q = $self->query();
		my $name = $q->param('name');
		my $id = $q->param('id');
		my $email = $q->param('email');
		my $debug = $self->routes_dbg; #dumps all the C::A::P::Routes info
		return $self->dump_html();
	}
	1;

Not that we did not have to also call run_modes() to register the run modes.
We will automatically register the route targets as run modes if there is not
already a run mode registered with that name, and we can call target as a
method.

=head1 EXPORT

Exported subs:

=over 1

=item C<routes>

	Is exported so it can be called from the CGI::Application app to receive the routes table.
	If no routes table is provided to the module, it will warn and return 0 and no I<harm> will be done to the CGI query params.

=item C<routes_root>

	This method makes possible to set a common root for all the routes passed to the plugin, to avoid unnecessary repetition.

=item C<routes_parse>

	Is exported in order to make the callback available into the CGI::Application based app. Not meant to be invoked manually.

=item C<routes_dbg>

	Is exported so you can see what happened on the Routes guts.

=back

=cut


=head1 FUNCTIONS

	routes
	routes_root
	routes_parse
	routes_dbg

Ideally, you shouldn't worry for the module functions. Just make sure to pass the routes and use the routes_dbg to see the guts of what happened if something isn't working as expected.

=head1 AUTHOR

Julián Porta, C<< <julian.porta at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-application-plugin-routes at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-Routes>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Application::Plugin::Routes


You can also look for information at:

=over 4


=item * github

L<http://github.com/Porta/cgi--application--plugin--routes/tree/master>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Application-Plugin-Routes>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Application-Plugin-Routes>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-Application-Plugin-Routes>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-Application-Plugin-Routes>

=back


=head1 ACKNOWLEDGEMENTS

Michael Peter's CGI::Application::Dispatch module that can be found here:
L<http://search.cpan.org/~wonko/CGI-Application-Dispatch>
I borrowed from him most of the routine that parses the url.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Julián Porta, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of CGI::Application::Plugin::Routes
