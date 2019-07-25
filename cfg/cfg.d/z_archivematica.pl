#
# Archivematica Bazaar Package
#
# Version 0.1
#

use EPrints::DataObj::Archivematica;

# Enable plugins
$c->{plugins}{"Export::Archivematica"}{params}{disable} = 0;
$c->{plugins}{"Export::Archivematica::EPrint"}{params}{disable} = 0;

# Add new dataset for tracking archivematica events
$c->{datasets}->{archivematica} = {
	class => "EPrints::DataObj::Archivematica",
	sqlname => "archivematica",
};

# Set user roles (edit not allowed as should only be updated by EPrints and export results
push @{$c->{user_roles}->{admin}}, qw{ +archivematica/view +archivematica/destroy };

$c->add_dataset_trigger( 'eprint', EPrints::Const::EP_TRIGGER_AFTER_COMMIT, sub
{
	my( %args ) = @_;
	my( $repo, $eprint, $changed ) = @args{qw( repository dataobj changed )};

 	## To Do ##
 	# Establish what has changed... and decide if we need to process a new Archivematica
 	# transfer... create a new Archivematica record if this EPrint doesn't already have 
 	# one, or update an existing one if it does.
 	
 	return EP_TRIGGER_OK;
});


