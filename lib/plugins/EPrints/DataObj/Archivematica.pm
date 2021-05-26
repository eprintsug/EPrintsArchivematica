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
		{ name => "uuid", type => "text", sql_index => 1 },
		{ 
			name => "result_log",
		  	type => "compound",
			multiple => 1,
			fields => [
				{ sub_name => "timestamp", type => "timestamp", },
				{ sub_name => "action", type => "set" , options => [qw( create_transfer update_transfer info )] }, # more actions may be added later
				{ sub_name => "comment", type => "text", allow_null => 1, input_cols => 20 }, # optional text comment
				{ sub_name => "result", type => "set", options => [qw( success fail )] },
        		],
		},
		{ name => "is_dirty", type => "boolean", } # used to record whether or not a new Archivematica transfer needs to be created for this record
	);
}

sub get_dataobj
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $ds = $session->dataset( $self->value( "datasetid" ) );
	return $ds->dataobj( $self->value( "dataobjid" ) );
}

# eg $a->add_to_record_log( "create_transfer", "this is a new transfer", "success" );
sub add_to_record_log
{
	my( $self, $action, $comment, $result ) = @_;

	my $timestamp = EPrints::Time::get_iso_timestamp();
	my @log = @{ $self->get_value( "result_log" ) };

	my $new_entry =
	{
		timestamp => $timestamp,
		action => $action,
		comment => $comment,
		result => $result,
	};

	push @log, $new_entry;
	$self->set_value( "result_log", \@log );
}

1;
