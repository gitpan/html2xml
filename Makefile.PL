use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	        => 'html2xml',
    'EXE_FILES'         => [ 'html2xml.pl' ],
    'PREREQ_PM'         => 
    {
              'HTML::TreeBuilder'     => 0,
	      'Encode'     => 0	
    },
    'VERSION_FROM'      => 'html2xml.pl', # finds $VERSION
    'dist'         => {
        'COMPRESS' => 'gzip',
        'SUFFIX'   => 'gz',
    },
);
