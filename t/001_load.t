# -*- perl -*-

use Test::More tests => 7;

BEGIN { 
	use_ok( q{HTML::Template::Associate} ); 
        use_ok( q{HTML::FormValidator} ); 
	use_ok( q{CGI} );
        use_ok( q{HTML::Template} );
}

my $cgi = CGI->new;
$cgi->param(q{company}, q{XYZ} );
$cgi->param(q{phone}, q{6041234561} );
$cgi->param(q{country}, q{Canada} ); 

my $profile = {
            optional     =>
                [ qw( company fax country ) ],
            required     =>
                [ qw( fullname phone email address city state zipcode ) ],
            constraints  =>
                {
                    email       => "email",
                    fax         => "american_phone",
                    phone       => "american_phone",
                    zipcode     => '/^\s*\d{5}(?:[-]\d{4})?\s*$/',
                    state       => "state",
                },
            defaults => {
                country => "Canada",
            },
};

my $validator = HTML::FormValidator->new;
my $results = $validator->check ( scalar $cgi->Vars, $profile );

my $associate = HTML::Template::Associate->new ( {
	 target => 'FormValidator',
         results => $results 
       } );

isa_ok ($associate, q{HTML::Template::Associate::FormValidator} );

my $template = HTML::Template->new(
        filename => 't/test.tmpl',
        associate => [ $cgi, $associate ],
        case_sensitive => 1 );

ok ( $template->query( name => q{VALID_company} ) eq q{VAR}, q{Valid Company Field} ); 
ok ( $template->query( name => q{VALID_phone} ) eq q{VAR}, q{Valid Phone Field} );
