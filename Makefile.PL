use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::Application::Plugin::Routes',
    AUTHOR              => 'Julián Porta <julian.porta@gmail.com>',
    VERSION_FROM        => 'lib/CGI/Application/Plugin/Routes.pm',
    ABSTRACT_FROM       => 'lib/CGI/Application/Plugin/Routes.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'CGI::Application' => 4,
    },
    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
     (MIN_PERL_VERSION => 5.006,
      META_MERGE => {
        resources=> {
          repository => 'http://github.com/Porta/cgi--application--plugin--routes/tree',
        },
        keywords => ['CGI::Application','Titanium','plugin','web','route'],
      },
      'LICENSE'		=> 'perl',
     ) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Application-Plugin-Routes-*' },
);
