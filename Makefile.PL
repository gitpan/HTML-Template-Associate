use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'HTML::Template::Associate',
    VERSION_FROM => 'lib/HTML/Template/Associate.pm', # finds $VERSION
    AUTHOR       => 'Alex Pavlovic (alex@taskforce-1.com)',
    ABSTRACT     => '',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44, 'HTML::FormValidator', 'HTML::Template', 'CGI' 
                    },
);
