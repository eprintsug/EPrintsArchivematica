#
# Archivematica Bazaar Package
#
# Version 0.1
#

use EPrints::DataObj::Archivematica;

# Enable plugins
$c->{plugins}{"Screen::EPrint::Staff::Archivematica"}{params}{disable} = 0;
$c->{plugins}{"Screen::Archivematica::Export"}{params}{disable} = 0;

$c->{plugins}{"Export::Archivematica"}{params}{disable} = 0;
$c->{plugins}{"Export::Archivematica::EPrint"}{params}{disable} = 0;

# Add new dataset for tracking archivematica events
$c->{datasets}->{archivematica} = {
	class => "EPrints::DataObj::Archivematica",
	sqlname => "archivematica",
};

# Set user roles (edit not allowed as should only be updated by EPrints and export results
push @{$c->{user_roles}->{admin}}, qw{ +archivematica/view +archivematica/destroy archive/eprint archivematica/export };

# Set archivematica transfer location
$c->{archivematica}->{path} = $c->{archiveroot}.'/archivematica';

# Include Derivatives?
$c->{DPExport}->{include_derivatives} = 1;

# example fields to trigger record creation
$c->{DPExport}->{trigger_fields}->{meta_fields} = [ qw/ title creators_name creators_id fileinfo / ]; 

$c->add_dataset_trigger( 'eprint', EPrints::Const::EP_TRIGGER_AFTER_COMMIT, sub
{
	my( %args ) = @_;
	my( $session, $eprint, $changed ) = @args{qw( repository dataobj changed )};

 	## To Do ##
 	# Establish what has changed... and decide if we need to process a new Archivematica
 	# transfer... create a new Archivematica record if this EPrint doesn't already have 
 	# one, or update an existing one if it does.

	my $action_required = 0;
	foreach my $f ( @{ $c->{DPExport}->{trigger_fields}->{meta_fields} } )
	{
		if( defined $changed->{ $f } )
		{
			print STDERR "New Archivematica transfer required due to field '$f' changes\n";
			$action_required = 1;
    			# last;
  		}
	}

	if( $action_required )
	{
		# create an archivematica record for this item if one doesnt exist
		# the process_transfers offline script can run over these and generate exports (and zip files)

		my $ds = $session->dataset( "archivematica" );
		my $searchexp = new EPrints::Search( session=>$session, dataset=>$ds );
		$searchexp->add_field( $ds->get_field( "datasetid" ), "eprint", "EQ" );
		$searchexp->add_field( $ds->get_field( "dataobjid" ), $eprint->id, "EQ" );
		my $list = $searchexp->perform_search;

		if( $list && $list->count() > 0 )
		{
			# take the first result and set is_dirty if its not already set
			my $a = $list->item(0);
			if( $a->get_value( "is_dirty" ) == 0 )
			{
				$a->set_value( "is_dirty", 1 );
				$a->commit();
			}
		}
		else
		{
			# create a new entry
			$session->dataset( "archivematica" )->create_dataobj({
				datasetid => "eprint",
				dataobjid => $eprint->id,
				is_dirty => 1,
			});
		}
	}

 	return EP_TRIGGER_OK;
});


