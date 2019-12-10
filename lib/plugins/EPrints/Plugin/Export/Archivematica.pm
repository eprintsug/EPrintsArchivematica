=head1 NAME

EPrints::Plugin::Export::Archivematica

=cut

package EPrints::Plugin::Export::Archivematica;

# Virtual super-class used to create transfers of Data Objects for Archivematica

use EPrints::Plugin::Export;

@ISA = ( "EPrints::Plugin::Export" );

use strict;

sub new
{
	my( $class, %params ) = @_;

	$params{mimetype} = 'application/gzip';

	return $class->SUPER::new( %params );
}

sub output_dataobj
{
	my ($self, $dataobj, %opts) = @_;

}

1;
