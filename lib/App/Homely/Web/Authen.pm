package App::Homely::Web::Authen {
    use 5.016;
    use warnings;
    
    use Mojo::Base 'Mojolicious::Controller';
    
    # Check authentication
    sub authen_check {
        my $self = shift;
        if ($self->is_authenticated) {
            $self->redirect_to('/dashboard');
        } else {
            $self->render(
                error       => undef,
                template    => 'authen/form',
            );
        }
    }
    
    sub authen_token {
        my $self = shift;
        
        if ($self->check_token($self->stash('token'))) {
            $self->redirect_to('/dashboard');
        } else {
            $self->render( 
                template    => 'authen/form',
                error       => 'Invalid access token! Please check your bookmarks.',
            );
        }
    }
    
    sub authen_post {
        my $self = shift;
        if ($self->check_token($self->param('access_token'))) {
            $self->redirect_to('/dashboard');
        } else {
            $self->render(
                template    => 'authen/form',
                error       => 'Invalid login token! Please try again.',
            );
        }
    }
    
    sub authen_logout {
        my ($self) = @_;
        my $user = delete $self->session->{_uid};
        $self->app->log->info("Logged out user $user");
        
        $self->render(
            template    => 'authen/logout',
        );
    }
    
    sub check_token {
        my ($self,$token) = @_;
        # TODO proper login checks
        if ($token eq 'AAA') {
            my $user = 'hase'; 
            $self->session('_uid',$user);
            $self->session('_expires',time() + 60*60); #$self->app->config
            $self->app->log->info("Logged in user $user via token");
            return 1;
        } else {
            $self->app->log->info("Failed login attempt from ".$self->tx->remote_address);
            return 0;   
        }
    }
}

1;