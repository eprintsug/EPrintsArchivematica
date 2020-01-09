package EPrints::Plugin::Screen::EPrint::Staff::Archivematica;

@ISA = ( 'EPrints::Plugin::Screen::EPrint' );

use strict;

sub new
{
        my( $class, %params ) = @_;

        my $self = $class->SUPER::new(%params);

        $self->{actions} = [qw/ create_archivematica_record /];

        $self->{appears} = [ {
                place => "eprint_editor_actions",
                action => "create_archivematica_record",
                position => 2100,
        }, ];

        return $self;
}

sub obtain_lock
{
        my( $self ) = @_;

        return $self->could_obtain_eprint_lock;
}

sub about_to_render
{
        my( $self ) = @_;

        $self->EPrints::Plugin::Screen::EPrint::View::about_to_render;
}

sub allow_create_archivematica_record
{
	my( $self ) = @_;

	return 0 unless $self->could_obtain_eprint_lock;

	my $dataobj = $self->{processor}->{eprint}; 

	return $self->{session}->current_user->has_role( "archive/eprint" );
}

sub action_create_archivematica_record
{
	my( $self ) = @_;

	my $session = $self->{session};

	$self->{processor}->{redirect} = $self->redirect_to_me_url()."&_current=2";

	my $eprint = $self->{processor}->{eprint};

	if( defined $eprint )
	{
		$session->dataset( "archivematica" )->create_dataobj({
			datasetid => "eprint",
			dataobjid => $eprint->id,
			is_dirty => 1,
		}); 
		$self->{processor}->add_message( "message", $self->html_phrase( "create_transfer" ) );
	}
}
