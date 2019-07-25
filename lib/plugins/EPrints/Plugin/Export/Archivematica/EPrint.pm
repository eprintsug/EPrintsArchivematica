=head1 NAME

EPrints::Plugin::Export::Archivematica::EPrint

=cut

package EPrints::Plugin::Export::Archivematica::EPrint;

use EPrints::Plugin::Export::Archivematica;

@ISA = ( "EPrints::Plugin::Export::Archivematica" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my( $self ) = $class->SUPER::new( %opts );

	$self->{name} = "Archivematica";
	$self->{accept} = [ 'dataobj/eprint' ]; 
	$self->{visible} = "all";

	return $self;
}

sub output_dataobj
{
	my( $self, $dataobj, %opts ) = @_;

	## To Do ##
	# Create directories in temporary location and 
	# populate with documents, XML, checksums, etc.
	# to generate an Archivematica transfer.
	#
	# Should record a result code, to be stored in 
	# the Archivematica record log for this DataObj
	#
	# Returns a tar.gz when successful

}

1;
