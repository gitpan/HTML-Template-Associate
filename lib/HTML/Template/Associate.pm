#$Id: Associate.pm,v 1.9 2003/08/02 03:01:55 alex Exp $

package HTML::Template::Associate;
use strict;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = qw ( $Revision: 1.9 $ )[1];
	@ISA         = qw (Exporter);
	#Give a hoot don't pollute, do not export more than needed by default
	@EXPORT      = qw ();
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}

use Carp;
use constant ERROR_OBJECT_CREATE => q{Cannot create %s target, make sure this class exists};
use constant ERROR_SUB_PARAM => q{Sub param not defined in your class, please provide concrete implementation for it};
use constant ERROR_SUB_INIT => q{Sub init not defined in your class, please provide concrete implementation for it};

########################################### main pod documentation begin ##

=head1 NAME

HTML::Template::Associate 

=head1 SYNOPSIS

  #Example usage with CGI and FormValidator as the target

  use CGI qw/:standard/;
  use HTML::FormValidator;
  use HTML::Template;
  use HTML::Template::Associate;

  my $cgi = CGI->new;
  #for testing purposes we can add some input to our cgi object
  $cgi->param( q{fullname}, q{John Doe} );
  $cgi->param( q{phone}, 6041112222 );
  $cgi->param( q{email}, q{invalid@email} );
  
  my $input_profile = {
	    optional     =>
		[ qw( company fax country ) ],
	    required     =>
		[ qw( fullname phone email address city state zipcode ) ],
	    constraints  =>
		{
		    email	=> "email",
		    fax		=> "american_phone",
		    phone	=> "american_phone",
		    zipcode	=> '/^\s*\d{5}(?:[-]\d{4})?\s*$/',
		    state	=> "state",
		},
	    defaults => {
		country => "Canada",
	    },
  };

  my $validator = HTML::FormValidator->new;
  my $results = $validator->check ( scalar $cgi->Vars, $input_profile ); 

  my $associate = HTML::Template::Associate->new( {
  	target => 'FormValidator', 
	results => $results,
        extra_arguments => [ $validator ] } ); #not needed but just illustrated

  my $template = HTML::Template->new(
	filename => 'test.tmpl', 
        associate => [ $cgi, $associate ] );

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

  <!-- We can also access our normal field names since $cgi object was passed as associate as well -->

  I think <TMPL_VAR NAME=country> is very big country. 

=head1 DESCRIPTION

  HTML::Template::Associate bridges gap between HTML::Template and 
  other modules that can be used in conjunction with it to do something 
  useful together, like for example HTML::FormValidator that can verify form inputs. 
  The primary reason I wrote this is that I needed something to bridge those two and 
  the thought of creating something more expandable came to mind.   

  The idea is that every associate object can map required data structure onto
  the one which corresponds to the one being documented publicly in the HTML::Template.
  The factory will then instantiate the target class and user can then make it available 
  to HTML::Template via associate argument during object construction. The data structures   then become automatically visible to your templates.

  This module is abstract class it provides no mapping functionality
  whatsoever, but rather defines common interface to all associate
  objects underneath it and acts as a object production factory.

  You should however use this module whenever you wish to access a
  concrete associate class that provides functionality you desire.

  I hope that with time more useful associate objects spring into existence.

=head1 USAGE

  #where $results = HTML::FormValidator::Results; for example

  my $associate = HTML::Template::Associate->new( {
        target => 'FormValidator',
        results => $results );

  Target is always last portion of your full class name, so if
  you had HTML::Template::Associate::XYZ the target would be XYZ

=head1 BUGS

  Maybe. If you see any make sure you let me know.

=head1 SUPPORT


=head1 AUTHOR

	Alex Pavlovic
	alex@taskforce-1.com
	http://www.taskforce-1.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

HTML::Template::Associate::FormValidator perl(1).

=cut

############################################# main pod documentation end ##


################################################ subroutine header begin ##

=head2 new

 Usage     : my $associate = HTML::Template::Associate->new ( target => 'FormValidator', results => $results );
 Purpose   : Constructs new associate object
 Returns   : associate instance
 Argument  : Hash of arguments ( target specifying object to be created, results specifying result set, optional extra_arguments specifying additional arguments to be passed inside target object )
 Throws    : Error in case target does not exist
 Comments  : Please note that target is always last portion of your full class name, so if you had HTML::Template::Associate::XYZ the target would be XYZ

=cut

################################################## subroutine header end ##


sub new {
        shift;
        my $params = shift;
        my $target = __PACKAGE__ . q{::} . $params->{target};
        eval "require $target";
        error( sprintf ( ERROR_OBJECT_CREATE, $target ) . qq{ [$@]} ) if ( $@ );
	my $self = bless ({}, ref ($target) || $target);
	$self->init ( $params );
	return ($self);
}

################################################ subroutine header begin ##

=head2 param

 Usage     : my $MyParam = $associate->param(q{MyParam});
 Purpose   : Retrieves param in a form suitable for access by HTML::Template
 Returns   : Single param or arrays suitable for loops 
 Argument  : Parameter name and optional value if setting it
 Throws    : Error in case subroutine was not implemented in concrete class
 Comments  : This subroutine should be redefined in concrete class

=cut

################################################## subroutine header end ##


sub param { carp ERROR_SUB_PARAM }; 


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


sub init { carp ERROR_SUB_INIT };



################################################ subroutine header begin ##

=head2 log

 Purpose   : Used internally to warn errors

=cut

################################################## subroutine header end ##

sub log   { shift; carp @_ }


################################################ subroutine header begin ##

=head2 error

 Purpose   : Used internally to die on errors                                 

=cut

################################################## subroutine header end ##

sub error { shift; croak @_ }


1; #this line is important and will help the module return a true value
__END__

