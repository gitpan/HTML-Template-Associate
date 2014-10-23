package HTML::Template::Associate;
use strict;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = '2.00';
	@ISA         = qw (Exporter);
	#Give a hoot don't pollute, do not export more than needed by default
	@EXPORT      = qw ();
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}

use constant ERROR_OBJECT_CREATE => 'Cannot create %s target, make sure this class exists';
use constant ERROR_SUB_INIT => 'Sub init not defined in your target class, please provide concrete implementation for it';
use constant FIELD_HASH => 'PARAMS';

########################################### main pod documentation begin ##

=head1 NAME

	HTML::Template::Associate - Associate relevant packages with HTML::Template 

=head1 SYNOPSIS

	#Example usage with FormValidator as the target 
	
	use CGI qw/:standard/;
	use Data::FormValidator;
	use HTML::Template;
	use HTML::Template::Associate;
	
	my $cgi = CGI->new;
	#for testing purposes we can add some input to our cgi object
	$cgi->param( 'fullname', 'John Doe' );
	$cgi->param( 'phone', 6041112222 );
	$cgi->param( 'email', 'invalid@email' );
	
	my $input_profile = {
		optional => [ qw( company fax country ) ],
		required => [ qw( fullname phone email address city state zipcode ) ],
		constraints  => {
			email => 'email',
			fax => 'american_phone',
			phone => 'american_phone',
			zipcode	=> '/^\s*\d{5}(?:[-]\d{4})?\s*$/',
			state => "state",
		},
		defaults => { country => "Canada" },
		msgs => {
			prefix=> 'error_',
			missing => 'Not Here!',
			invalid => 'Problematic!',
			invalid_seperator => ' <br /> ',
			format => 'ERROR: %s',
			any_errors => 'some_errors',
		}
	};
	
	my $validator = Data::FormValidator->new;
	my $results = $validator->check ( scalar $cgi->Vars, $input_profile ); 
	
	my $associate = HTML::Template::Associate->new( {
		target => 'FormValidator', 
		results => $results,
		extra_arguments => [ $validator ] #not needed but just illustrated
	} ); 
	
	my $template = HTML::Template->new(
		filename => 'test.tmpl', 
		associate => [ $cgi, $associate ] 
	);
	
	print $template->output;
	
	#and in our test.tmpl file we could have
	
	Valid Fields:<br>
	<TMPL_LOOP NAME=VALID_FIELDS>
	Field Name: <TMPL_VAR NAME=FIELD_NAME><br>
	Field Value: <TMPL_VAR NAME=FIELD_VALUE><br> 
	</TMPL_LOOP>
	
	Missing Fields:<br>
	<TMPL_LOOP NAME=MISSING_FIELDS>
	Field Name: <TMPL_VAR NAME=FIELD_NAME><br>
	Field Value: <TMPL_VAR NAME=FIELD_VALUE><br> 
	</TMPL_LOOP>
	
	<TMPL_IF NAME=INVALID_phone>
	Phone: <TMPL_VAR NAME="phone"> you supplied is invalid.		
	</TMPL_IF>
	
	<TMPL_IF NAME=MISSING_city> 
	City name is missing, please fix this.
	</TMPL_IF>
	
	<!-- We can also access our normal field names 
	since $cgi object was passed as associate as well -->
	
	I think <TMPL_VAR NAME=country> is very big country. 
	
	<!-- Optional use of Data::FormValidator::Results msgs interface -->
	
	Message Fields:
	
	<TMPL_LOOP NAME=MSGS_FIELDS>
	Field Name: <TMPL_VAR NAME=FIELD_NAME><br>
	Field Value: <TMPL_VAR NAME=FIELD_VALUE><br>
	</TMPL_LOOP>
	
	<TMPL_IF NAME=MSGS_error_city>
	Our default error message set in the profiling code is: 
		<TMPL_VAR NAME=MSGS_error_city> 
	</TMPL_IF>

	#Example usage with DBI as the target
	use DBI;
	use HTML::Template;
	use HTML::Template::Associate;
	
	#initiliaze your $dbh ...
	
	my $results_foo = $dbh->selectall_hashref (
		'SELECT foo FROM bar WHERE baz = ?',
		'foo_id',
		{},
		$baz
	);
	
	my $results_bar = $dbh->selectall_hashref (
		'SELECT foo, bar FROM bar WHERE baz = ?',
		[ 'foo_id', 'bar_id' ] ,
		{},
		$baz
	);
	
	my $results_moo = $dbh->selectrow_hashref ( 'SELECT x, y FROM z LIMIT 1' );
	
	my @results_array = $dbh->selectrow_array ( 'SELECT x FROM z' );
	
	my $associate = HTML::Template::Associate->new( {
		target => 'DBI',
		create => [ {
				results => $results_foo,
				name => 'my_loop',
				type => 'selectall_hashref'
			}, {
				results => $results_bar,
				name => 'my_other_loop',
				type => 'selectall_hashref'
			}, {
				results => $results_moo,
				type => 'selectrow_hashref',
				name => 'my_params'
			}, {
				results => \@results_array,
				type => 'selectrow_array',
				name => 'my_array_params'
			}
		]
	} );
	
	my $template = HTML::Template->new (
		filename => 'test.tmpl',
		associate => [ $associate ],
		die_on_bad_params => 0
	);
	
	print $template->output();
	
	#sample.tmpl
	
	<!-- TMPL_LOOP NAME="my_loop" -->
		Foo is:<!-- TMPL_VAR NAME="foo" -->
	<!-- /TMPL_LOOP -->
	
	<!-- TMPL_LOOP NAME="my_other_loop" -->
		Foo is:<!-- TMPL_VAR NAME="foo" -->
		Bar is:<!-- TMPL_VAR NAME="bar" -->
	<!-- /TMPL_LOOP -->
	
	x is:<!-- TMPL_VAR NAME="my_params.x" -->
	y is:<!-- TMPL_VAR NAME="my_params.y" -->
	
	x via $dbh->selectrow_array is:<!-- TMPL_VAR NAME="my_array_params.0 -->

=head1 DESCRIPTION

	HTML::Template::Associate bridges gap between HTML::Template and 
	other modules that can be used in conjunction with it to do something 
	useful together, like for example Data::FormValidator that can verify 
	form inputs. 
	
	The idea is that every associate object can map required data structure 
	onto the one which corresponds to the one found in HTML::Template.
	The factory will then instantiate the target class and user can then make 
	it available to HTML::Template via associate argument during object 
	construction. The data structures then become automatically visible to 
	your templates.
	
	This module is abstract class it provides no mapping functionality
	whatsoever, but rather defines common interface to all associate
	objects underneath it and acts as a object production factory.
	You should however use this module whenever you wish to access a
	concrete associate class that provides functionality you desire.

=head1 USAGE

	#where $results = Data::FormValidator::Results; for example
	my $associate = HTML::Template::Associate->new( {
		target => 'FormValidator',
		results => $results 
	} );

	Target is always last portion of your full class name, so if
	you had HTML::Template::Associate::XYZ the target would be XYZ

=head1 BUGS

	Maybe. If you see any make sure you let me know.

=head1 SUPPORT


=head1 AUTHOR

	Alex Pavlovic
	alex.pavlovic@taskforce-1.com
	http://www.taskforce-1.com

=head1 COPYRIGHT

	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.
	
	The full text of the license can be found in the
	LICENSE file included with this module.

=head1 SEE ALSO

	HTML::Template::Associate::FormValidator HTML::Template::Associate::DBI perl(1).

=cut

############################################# main pod documentation end ##


################################################ subroutine header begin ##

=head2 new

	Usage     : my $associate = HTML::Template::Associate->new ( $target_arguments );
	Purpose   : Constructs new Associate object
	Returns   : Associate instance
	Argument  : Refer to the target
	Throws    : Error in case target does not exist
	Comments  : None

=cut

################################################## subroutine header end ##

sub new {
        shift;
        my $params = shift;
        my $target = __PACKAGE__ . '::' . $params->{target};
        eval "require $target";
        error( sprintf ( ERROR_OBJECT_CREATE, $target ) . " [$@]" ) if ( $@ );
	my $self = bless ({}, ref ($target) || $target);
	$self->init ( $params );
	return ($self);
}

################################################ subroutine header begin ##

=head2 param

	Usage     : my $MyParam = $associate->param('MyParam');
	Purpose   : Retrieves param in a form suitable for access by HTML::Template
	Returns   : Single param or arrays suitable for loops 
	Argument  : Parameter name and optional value if setting it
	Throws    : Error in case subroutine was not implemented in concrete class
	Comments  : This subroutine should be redefined in concrete class

=cut

################################################## subroutine header end ##

sub param {
	my ( $self, $field, $value ) = @_;
	$self->{&FIELD_HASH}->{$field} = $value if $value;
	return keys %{ $self->{&FIELD_HASH} } unless $field;
	return $self->{&FIELD_HASH}->{$field};
}

################################################ subroutine header begin ##

=head2 init

	Usage     : $self->init ( $params );
	Purpose   : Provides basic initiliazation for the target class
	Returns   : true or false depending on whether initilization was succesful
	Argument  : hash of parameters passed to factory during object construction
	Throws    : Error in case subroutine was not implemented in concrete class
	Comments  : This subroutine should be redefined in concrete class

=cut

################################################## subroutine header end ##


sub init { warn ERROR_SUB_INIT };


################################################ subroutine header begin ##

=head2 error

	Purpose   : Used internally to die on errors

=cut

################################################## subroutine header end ##

sub error { shift; die @_ }

1; 

__END__
