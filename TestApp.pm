package TestApp;
use strict;
use warnings;


use base qw/CGI::Application/;
use CGI::Application::Plugin::Routes;
use Data::Dumper;





##############################
#####  OVERRIDE METHODS  #####
##############################

sub setup {
	my $self = shift;

	$self->routes_table([
		'' => 'home' ,
		'/showform/:id'  => 'show_form',
		'/coco/:id'  => 'do_search',
		'/sorongo/:name/:id/:email'  => 'view_details',
	]);
	$self->start_mode('show_form');

	$self->run_modes([qw/
		show_form
		do_search
		view_details
	/]);

	$self->tmpl_path('templates/');
}


sub teardown {
	my $self = shift;
}



##############################
#####  RUN-MODE METHODS  #####
##############################


sub show_form {
	my $self = shift;

	my $q = $self->query();
	warn "a ver ", $q->param('id');

	return $self->dump_html();
}



sub do_search {
	my $self = shift;

	warn "llegué ";

	return $self->dump_html();
}



sub view_details {
	my $self = shift;
	warn "a ver ", $self->query->param('id');
	my $q = $self->query();

	return $self->dump_html();
}







#############################
#####  PRIVATE METHODS  #####
#############################



1;



=pod


=head1 NAME

WidgetBrowser -
Abstract of web application....


=head1 SYNOPSIS

  use WidgetBrowser;
  my $app = WidgetBrowser->new();
  $app->run();


=head1 DESCRIPTION

Overview of functionality and purpose of
web application module WidgetBrowser...


=head1 RUN MODES

=over 4


=item show_form

Description of run-mode show_form...

  * Purpose
  * Expected parameters
  * Function on success
  * Function on failure



=item do_search

Description of run-mode do_search...

  * Purpose
  * Expected parameters
  * Function on success
  * Function on failure



=item view_details

Description of run-mode view_details...

  * Purpose
  * Expected parameters
  * Function on success
  * Function on failure




=back



=head1 AUTHOR

Author of Module <author@module>


=head1 SEE ALSO

L<DBI>, L<CGI::Application>

=cut

