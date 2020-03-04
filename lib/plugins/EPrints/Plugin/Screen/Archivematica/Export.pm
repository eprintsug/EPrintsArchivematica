package EPrints::Plugin::Screen::Archivematica::Export;

use EPrints::Plugin::Screen;
@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{actions} = [qw/ export /];

	$self->{icon} = "action_unpack.png"; # uses a button rather than an icon, fix.

	$self->{appears} = [
		{
			place => "dataobj_actions",
			action => "export",
			position => 1600,
		},
		{
			place => "dataobj_view_actions",
			action => "export",
			position => 1600,
		},
	];
	
	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;
       	return $self->{session}->current_user->has_role( "archivematica/export" )
}

sub properties_from
{
        my( $self ) = @_;

        my $session = $self->{session};

        $self->SUPER::properties_from;

        $self->{processor}->{archivematica} = $session->dataset( 'archivematica' )->dataobj( $session->param( 'dataobj' ) );
}

sub allow_export { return shift->can_be_viewed }

sub action_export
{
	my( $self ) = @_;

	$self->properties_from;

	# first get the dataobj we want to create a transfer for
	my $archivematica = $self->{processor}->{archivematica};
	my $dataobj = $archivematica->get_dataobj;

	# then call the export plugin, passing it our id at the same time
	my $result = $dataobj->export( "Archivematica::EPrint", amid => $archivematica->id );
	
}

sub render_action_icon
{
        my( $self, $params ) = @_;
print STDERR "in here render_action_icon\n";
        return $self->_render_action_aux( $params, 1 );
}


sub render
{
	my( $self ) = @_;
	return $self->{session}->make_text( "Screen not implemented. (lib)" );
}

1;
