=head1 NAME

EPrints::Plugin::Export::Archivematica::EPrint

=cut

package EPrints::Plugin::Export::Archivematica::EPrint;

use EPrints::Plugin::Export::Archivematica;
use File::Copy;
use Digest::MD5 qw(md5_hex);

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
	my $session = $self->{session};

	my $amid = $opts{amid};

	# create directory to store exported files
	my $target_path = $session->config( "archivematica", "path" ) . "/$amid";
	my $objects_path = "$target_path/objects";
	my $metadata_path = "$target_path/metdadata";	

	### objects
	$self->_make_dir( $objects_path );

	## documents
	my $documents_path = "$objects_path/documents";
	$self->_make_dir( $documents_path );

	my %hash_cache;	# store checksums to save recalculating them

	# get the main, non-volatile documents
	my @docs = $dataobj->get_all_documents;
	foreach my $doc ( @docs )
	{
		# create a directory for each doc
		my $doc_path= "$documents_path/documentid-" . $doc->id; 
		$self->_make_dir( $doc_path );

		# and create a files directory in the doc directory
		my $files_path = "$doc_path/files";
		$self->_make_dir( $files_path );

		# and then create a file directory for each file
		foreach my $file ( @{$doc->get_value( "files" )} )
		{
			my $file_path = "$files_path/" . $file->id;
			$self->_make_dir( $file_path );
		
			# and copy the file into the new file dir
			my $filename = $file->get_value( "filename" );
			my $local_path = $doc->local_path . "/" . $filename;

			my $h = $file->get_value( 'hash' );
			my $ht = $file->get_value( 'hash_type' );

			$hash_cache{ "$file_path/$filename" } = $h if $h && $ht && $ht eq "MD5";
			copy($local_path, "$file_path/$filename") or die "Copy failed: $!";
		}
	}

	## derivatives
	if( $session->config( 'DPExport', 'include_derivatives' ) ) # only include derivatives if enabled
	{
		my $derivatives_path = "$objects_path/derivatives";
		$self->_make_dir( $derivatives_path );

		# get the volatile documents
		@docs = @{$dataobj->get_value( "documents" )};
		foreach my $doc ( @docs )
		{
			next unless $doc->has_relation( undef, "isVolatileVersionOf" );

			# and create a files directory in the doc directory
			my $pos = $doc->get_value( "pos" );
	                my $pos_path = "$derivatives_path/$pos";
			$self->_make_dir( $pos_path );

			# and then copy the files into the pos directory
        	        foreach my $file ( @{$doc->get_value( "files" )} )
                	{
	                        my $filename = $file->get_value( "filename" );
        	                my $file_path = $doc->local_path . "/" . $filename;

				my $h = $file->get_value( "hash" );
				my $ht = $file->get_value( "hash_type" );

				$hash_cache{ "$pos_path/$filename" } = $h if $h && $ht && $ht eq "MD5";
                	        copy($file_path, "$pos_path/$filename") or die "Copy failed: $!";
	                }
		}
	}

	### metadata
	$self->_make_dir( $metadata_path );

	## ep3.xml
	my $xml = $session->xml;
        my $doc = $xml->parse_string( $dataobj->export( "XML" ) );
	EPrints::XML::write_xml_file( $doc, "$metadata_path/EP3.xml" );
	
	## revisions 
	# create a directory to copy the revisions to
	my $revisions_path = "$metadata_path/revisions";
	$self->_make_dir( $revisions_path);

	# now copy the actual revisions
	my $eprint_revisions_path = $dataobj->local_path . "/revisions";
	opendir my $eprint_revisions_dir, "$eprint_revisions_path" or die "Cannot open directory: $!";
	my @revisions = readdir $eprint_revisions_dir;
	foreach my $revision ( @revisions )
	{
		if( $revision =~ /^[\d]+\.xml$/ )
		{
			copy("$eprint_revisions_path/$revision", "$revisions_path/$revision") or die "Copy failed: $!";
		}
	}

	## Dublin Core JSON
	# first get the generic DC export plugin and use it to get an array of data
        my $dc_export = $session->plugin( "Export::DC" );
	my $dc_metadata = $dc_export->convert_dataobj( $dataobj );

	# and then convert it into JSON by creating a hash of data and passing that to do the JSON export plugin
	my $epdata = {};
	foreach my $metadata ( @{$dc_metadata} )
        {
		my $key = "dc." . $metadata->[0];
		my $value = $metadata->[1];
		if( exists $epdata->{$key} ) # more than one entry for this key, turn value into an array
		{
			my @new_values;
			push @new_values, $epdata->{$key};
			push @new_values, $value;
			$epdata->{$key} = \@new_values;
		}
		else 
		{
	        	$epdata->{$key} = $value;        
		}
	}
	my $json_export = $session->plugin( "Export::JSON" );
	my $json = $json_export->output_dataobj( $epdata );

	# now write the resulting json to file
	my $dc_file_path = "$metadata_path/metadata.json";
	open(my $fh, '>', $dc_file_path) or die "Could not open file '$dc_file_path' $!";
	print $fh $json;
	close $fh;

	## Checksum manifest
	# get all the files from the objects directory
	my @file_paths;
	$self->_read_dir( $objects_path, \@file_paths );
	
	# set up the manifest file
	my $manifest_file_path = "$metadata_path/checksum.md5";
	open(my $manifest_fh, '>', $manifest_file_path) or die "Could not open file '$manifest_file_path' $!";
	
	# loop through the files in the objects dir and add them to manifest
	foreach my $file_path ( @file_paths )
	{
		open(my $fh, '<', $file_path) or die "Could not open file '$file_path' $!";
		my $ctx = Digest::MD5->new;
		$ctx->addfile( $fh );
		my $digest = $ctx->hexdigest;
		close $fh;

		# Check if the recorded checksum matches the one just calculated.
		# TODO : For now add an alert in the manifest, later we need to act according to local config
		my $info = ( defined $hash_cache{ $file_path } && $hash_cache{ $file_path } ne $digest ) ? " # !checksum mismatch!" : "";

		print $manifest_fh $digest . " " . $file_path . $info . "\n";
	}
	close $manifest_fh;
}	

sub _make_dir
{
	my( $self, $dir ) = @_;

	unless( -d $dir )
        {
                EPrints::Platform::mkdir( $dir );
        }

}

sub _read_dir
{
	my( $self, $path, $file_paths ) = @_;

	if( -d $path ) # we have a directory
	{
		opendir my $dir, "$path" or die "Cannot open directory: $!";
		my @contents = readdir $dir;
		closedir $dir;
		foreach my $item ( @contents )
		{
			next if( $item eq "." || $item eq "..");

			$self->_read_dir( "$path/$item", $file_paths );
		}
	}
	elsif( -f $path ) # we have a file
	{
		push @$file_paths, $path;
		return $file_paths;
	}	
}

1;
