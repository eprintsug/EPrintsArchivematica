#
# Archivematica Bazaar Package
#
# Version 1.2
#

use EPrints::DataObj::Archivematica;

# Enable plugins
$c->{plugins}{"Screen::EPrint::Staff::Archivematica"}{params}{disable} = 0;
$c->{plugins}{"Screen::Archivematica::Export"}{params}{disable} = 0;

$c->{plugins}{"Export::Archivematica"}{params}{disable} = 0;
$c->{plugins}{"Export::Archivematica::EPrint"}{params}{disable} = 0;

# Hide from public interface
$c->{plugins}->{"Export::Archivematica::EPrint"}->{params}->{visible} = "staff";

# Add new dataset for tracking archivematica events
$c->{datasets}->{archivematica} = {
	class => "EPrints::DataObj::Archivematica",
	sqlname => "archivematica",
};

# Set user roles (edit not allowed as should only be updated by EPrints and export results
push @{$c->{user_roles}->{admin}}, qw{ +archivematica/view +archivematica/destroy archive/eprint archivematica/export };

# Set archivematica transfer location
$c->{archivematica}->{path} = $c->{archiveroot}.'/archivematica';


# Automatically generate missing checksums in EPrints database during export
$c->{DPExport}->{add_missing_checksums} = 1;

# Include Derivatives?
$c->{DPExport}->{include_derivatives} = 1;

$c->{DPExport}->{trigger_fields}->{meta_fields} = [ qw/ title creators_name creators_id fileinfo / ]; 

$c->add_dataset_trigger( 'eprint', EPrints::Const::EP_TRIGGER_AFTER_COMMIT, sub
{
	my( %args ) = @_;
	my( $session, $eprint, $changed ) = @args{qw( repository dataobj changed )};
	my $status = $eprint->value("eprint_status");
	
 	## To Do ##
 	# Establish what has changed... and decide if we need to process a new Archivematica
 	# transfer... create a new Archivematica record if this EPrint doesn't already have 
 	# one, or update an existing one if it does.

#use Data::Dumper;
#print STDERR Dumper( $changed ) . "\n";
 	
	#Act only on live eprints, not what is in workarea and buffer
	if ($status eq "archive"){
	
		my $action_required = 0;
		foreach my $f ( @{ $c->{DPExport}->{trigger_fields}->{meta_fields} } )
		{
			if( defined $changed->{ $f } )
			{
				#print STDERR "New Archivematica transfer required due to field '$f' changes\n";
				$action_required = 1;
					# last;
			}
		}

		if( $action_required)
		{
			# create an archivematica record for this item if one doesnt exist
			# an offline script can run over these and generate exports (and zip files)

			my $ds = $session->dataset( "archivematica" );
			my $searchexp = new EPrints::Search( session=>$session, dataset=>$ds );
			$searchexp->add_field( $ds->get_field( "datasetid" ), "eprint", "EQ" );
			$searchexp->add_field( $ds->get_field( "dataobjid" ), $eprint->id, "EQ" );
			my $list = $searchexp->perform_search;

			if( $list && $list->count() > 0 )
			{
				#print STDERR "trigger: use existing archivematica entry\n";
				# take the first result and set is_dirty if its not already set
				my $a = $list->item(0);
				if( $a->get_value( "is_dirty" ) eq 'FALSE' )
				{
					$a->set_value( "is_dirty", 'TRUE' );
					$a->add_to_record_log( "info", "trigger new transfer", "success" );
					$a->commit();
				}
			}
			else
			{
				# create a new entry
				#print STDERR "trigger: create new archivematica entry\n";
				my $am=$session->dataset( "archivematica" )->create_dataobj({
					datasetid => "eprint",
					dataobjid => $eprint->id,
					is_dirty => 'TRUE',
				});
				$am->add_to_record_log( "create_transfer", "created via trigger", "success" );
				$am->commit();
			}
		}
	
	}
 	return EP_TRIGGER_OK;
});

