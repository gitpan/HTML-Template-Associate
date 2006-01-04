package HTML::Template::Associate::DBI;
use strict;

BEGIN {
	use Exporter ();
	use Storable qw ( dclone );
	require HTML::Template::Associate;
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = '1.16';
	@ISA         = qw ( HTML::Template::Associate Exporter);
	#Give a hoot don't pollute, do not export more than needed by default
	@EXPORT      = qw ();
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}

use constant METHOD_TYPE_SELECTALL_HASHREF => q{selectall_hashref};
use constant METHOD_TYPE_SELECTROW_HASHREF => q{selectrow_hashref};
use constant METHOD_TYPE_FETCHALL_HASHREF => q{fetchall_hashref};
use constant METHOD_TYPE_FETCHROW_HASHREF => q{fetchrow_hashref};
use constant METHOD_TYPE_SELECTALL_ARRAYREF => q{selectall_arrayref};
use constant METHOD_TYPE_SELECTCOL_ARRAYREF => q{selectcol_arrayref};
use constant METHOD_TYPE_SELECTROW_ARRAY => q{selectrow_array};
use constant METHOD_TYPE_SELECTROW_ARRAYREF => q{selectrow_arrayref};
use constant METHOD_TYPE_FETCHROW_ARRAY => q{fetchrow_array};
use constant METHOD_TYPE_FETCHROW_ARRAYREF => q{fetchrow_arrayref};
use constant METHOD_TYPE_FETCHALL_ARRAYREF => q{fetchall_arrayref};
use constant FIELD_HASH => q{PARAMS};
use constant ERROR_MISSING_FIELD => q{Field %s does not exist in the lookup table};

=head1 NAME

HTML::Template::Associate::DBI - HTML::Template::Associate DBI plugin 

=head1 SYNOPSIS

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

	This class is not intended to be used directly but rather through a 
	HTML::Template::Associate. It provides concrete class functionality, it
	will take specific DBI method results and reconstruct data structure
	to the one appropriate for use by the HTML::Template.  	

	Supported DBI method types 
	* selectall_hashref
	* selectrow_hashref
	* fetchall_hashref
	* fetchrow_hashref
	* selectall_arrayref
	* selectcol_arrayref
	* selectrow_array
	* selectrow_arrayref
	* fetchrow_array
	* fetchrow_arrayref
	* fetchall_arrayref

=head1 METHODS

=over 4

=item init

Initializes the mapper

=cut

sub init {
	my ( $self, $params ) = @_;
	my $create = $params->{create};
	
	for ( @$create ) {
		my $method_type = $_->{type};
		my $param_name = $_->{name};
		my $results = $self->copy_structure ( $_->{results} );
		
		if ( $method_type eq METHOD_TYPE_SELECTALL_HASHREF ) {
			$self->init_selectall_hashref ( $results, $param_name );
		} elsif ( $method_type eq METHOD_TYPE_SELECTROW_HASHREF ) {
			$self->init_selectrow_hashref ( $results, $param_name );
		} elsif ( $method_type eq METHOD_TYPE_FETCHALL_HASHREF ) {
			$self->init_selectall_hashref ( $results, $param_name );
		} elsif ( $method_type eq METHOD_TYPE_FETCHROW_HASHREF ) {
			$self->init_selectrow_hashref ( $results, $param_name );
		} elsif ( $method_type eq METHOD_TYPE_SELECTALL_ARRAYREF ) {
			$self->init_selectall_arrayref ( $results, $param_name );
		} elsif ( $method_type eq METHOD_TYPE_SELECTCOL_ARRAYREF ) {
			$self->init_selectcol_arrayref ( $results, $param_name );
		} elsif ( $method_type eq METHOD_TYPE_SELECTROW_ARRAY ) {
			$self->init_selectcol_arrayref ( $results, $param_name );
		} elsif ( $method_type eq METHOD_TYPE_SELECTROW_ARRAYREF ) {
			$self->init_selectcol_arrayref ( $results, $param_name );
		} elsif ( $method_type eq METHOD_TYPE_FETCHROW_ARRAY ) {
			$self->init_selectcol_arrayref ( $results, $param_name );			
		} elsif ( $method_type eq METHOD_TYPE_FETCHROW_ARRAYREF ) {
			$self->init_selectcol_arrayref ( $results, $param_name );						
		} elsif ( $method_type eq METHOD_TYPE_FETCHALL_ARRAYREF ) {
			ref $results->[0] eq 'HASH' ? 
				$self->param ( $param_name, $results ) :
					$self->init_selectall_arrayref ( $results, $param_name );
		}
	}
	return $self;                          
}

=item init_selectall_hashref

Transform using selectall_hashref return format.

=cut

sub init_selectall_hashref {
	my ( $self, $results, $param_name ) = @_;
	my $values = [];
	$self->selectall_hashref_build ( $results, $values );
	$self->param ( $param_name, $values );	
}

=item init_selectrow_hashref

Transform using selectrow_hashref return format.

=cut

sub init_selectrow_hashref {
	my ( $self, $results, $param_name ) = @_;
	for ( keys %$results ) {
		$self->param ( $param_name . '.' . $_, $results->{$_} );
	}
}

=item init_selectall_arrayref

Transform using selectall_arrayref return format.

=cut

sub init_selectall_arrayref {
	my ( $self, $results, $param_name ) = @_;
	my $values = [];
	for ( @$results ) {
		my @hash_keys = ( 0 .. ( scalar ( @$_ ) - 1 ) );
		my $new_hash = {};
		@$new_hash{@hash_keys} = @$_;
		push @$values, $new_hash; 
	}
	$self->param ( $param_name, $values );
}

=item init_selectcol_arrayref

Transform using selectcol_arrayref return format.

=cut

sub init_selectcol_arrayref {
	my ( $self, $results, $param_name ) = @_;
	for ( 0 .. ( scalar ( @$results ) - 1 ) ) {
		$self->param ( "$param_name." . $_, $results->[$_] );
	}
}

=item param

Store param.

=cut

sub param {
	my ( $self, $field, $value ) = @_;
	$self->{&FIELD_HASH}->{$field} = $value if defined $value;
	return keys %{ $self->{&FIELD_HASH} } unless $field;
	$self->SUPER::log ( sprintf ( ERROR_MISSING_FIELD, $field ) ) unless exists $self->{&FIELD_HASH}->{$field};
	return $self->{&FIELD_HASH}->{$field};
}

sub selectall_hashref_build {
	my ( $self, $results, $values ) = @_;
	for ( keys %$results ) {
		if ( ref $results->{$_} eq 'HASH' ) {
			$self->selectall_hashref_build (
				$results->{$_},
				$values,
			);
		} else {
			push @$values, $results;
			last;
		}
 	}
}

sub copy_structure {
	my ( $self, $source ) = @_;
	return dclone ( $source );
}

=head1 BUGS

	If you find any please report to author.

=head1 SUPPORT

	See License.

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

	L<HTML::Template::Associate>, L<DBI> perl(1).

=cut

1; 

__END__
