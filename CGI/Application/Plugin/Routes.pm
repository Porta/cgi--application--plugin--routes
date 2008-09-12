package CGI::Application::Plugin::Routes;
use base 'Exporter';

use Data::Dumper;
use strict;
use vars qw($VERSION @ISA @EXPORT);


@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	&routes_parse
	&routes_table
);


$VERSION = '0.1';

sub import {
	my $caller = scalar(caller);
	$caller->add_callback('prerun', 'routes_parse');
	goto &Exporter::import;
}

sub routes_table {
	my ($self, $table) = @_;
	$self->{'Application::Plugin::Routes::__dispatch_table'} = $table;
}



sub routes_parse {
	my ($self) = @_;
	my $path = $self->query->path_info;
	# get the module name from the table
	my $table = $self->{'Application::Plugin::Routes::__dispatch_table'};
	unless(ref($table) eq 'ARRAY') {
		warn "[Application::Plugin::Routes::__parse_path] Invalid or no dispatch table!\n";
		return;
	}
	# look at each rule and stop when we get a match
	for(my $i = 0 ; $i < scalar(@$table) ; $i += 2) {
		my $rule = $table->[$i];
		# are we trying to dispatch based on HTTP_METHOD?
		my $http_method_regex = qr/\[([^\]]+)\]$/;
		if($rule =~ /$http_method_regex/) {
			my $http_method = $1;
			# go ahead to the next rule
			#next unless lc($1) eq lc($self->_http_method);
			# remove the method portion from the rule
			$rule =~ s/$http_method_regex//;
		}
		# make sure they start with a '/' to match how PATH_INFO is formatted
		$rule = "/$rule" unless(index($rule, '/') == 0);
		#so far, we dont need this
		#$rule = "$rule/" if(substr($rule, -1) ne '/');
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
#         warn
#           "[Dispatch] Trying to match '${path}' against rule '$table->[$i]' using regex '${rule}'\n";
		# if we found a match, then run with it
		if(my @values = ($path =~ m#^$rule$#)) {
			#warn "[Dispatch] Matched! ${path} \n";
			$self->{'Application::Plugin::Routes::__match'} = $path;
			my %named_args;
			$self->param('rm',$table->[++$i]);
			$self->prerun_mode($table->[$i]);
			@named_args{@names} = @values if @names;
			#force params into $self->query. NOTE that it will overwrite any existing param with the same name
			foreach my $k (keys %named_args){
				$self->query->param("$k", $named_args{$k});
			}
			$self->{'Application::Plugin::Routes::__r_params'} = \%named_args;
		}else{
			$self->{'Application::Plugin::Routes::__errors'} .= " No match between " . $rule . " and " . $path;
		}
	}
}

1;
__END__