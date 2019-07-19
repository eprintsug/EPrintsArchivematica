package EPrints::DataObj::Archivematica;

use EPrints;
use EPrints::DataObj;

@ISA = ( 'EPrints::DataObj' );

use strict;

sub get_dataset_id { "archivematica" }

sub get_system_field_info
{
	my( $class ) = @_;
	
	return
	(
		{ name => "amid", type => "counter", sql_counter => "archivematica", sql_index => 1 },
		{ name => "datasetid", type => "id", required => 1, sql_index => 1 },
		{ name => "dataobjid", type => "id", required => 1, sql_index => 1 },
		{ 
			name => "result_log",
		  	type => "compound",
			multiple => 1,
			fields => [
				{ sub_name => "timestamp", type => "timestamp", },
				{ sub_name => "action", type => "set" , options => [qw( create_transfer )] }, # more actions may be added later
				{ sub_name => "result", type => "set", options => [qw( success fail )] },
        		],
		},
		{ name => "is_dirty", type => "boolean", } # used to record whether or not a new Archivematica transfer needs to be created for this record
  );
}


sub add_to_record_log
{
	my( $class, $action, $result_code ) = @_;

	# To do: Add time, action and result to the record log
}

1;
