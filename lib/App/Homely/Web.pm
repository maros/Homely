package App::Homely::Web {
    use 5.014; 
    use warnings;
    
    use Mojo::Base 'Mojolicious';
    use Mojo::Server::PSGI;
    
    use EV;
    use AnyEvent;
    use Twiggy::Server;
    use Log::Any qw($log);
    
    use App::Homely::Web::Base;
    use App::Homely::Web::Authen;
    
    sub startup {
        my $self = shift;
        
        $log->info('Initialize web-server');
        
        my $core = App::Homely::Core->instance;
        
        # Setup logging
        #$self->log($log);
        
        # Setup user 
        $self->helper(is_authenticated => sub {
            my $c = shift;
            return 0
                unless ($c->session('_uid'));
            return 0
                unless ($c->session('_expires') > time);
                
            return 1;
        });
 
        # Set secret
        $self->secrets([$core->config->get('web/secret')]); 
        
        # Setup routes
        my $r = $self->routes;
        
        $r->add_condition(authenticated => sub {
            my ($r, $c, $captures, $required) = @_;
            return (!$required || $c->is_authenticated) ? 1 : 0;
        });
        
        $r->route('/')
            ->via('GET')
            ->to(controller => 'authen', action => 'authen_check');
        
        $r->route('/authen')
            ->via('POST')
            ->to(controller => 'authen', action => 'authen_post');
        
        $r->route('/authen/:token')
            ->via('GET')
            ->to(controller => 'authen', action => 'authen_token');
            
        $r->route('/logout')
            ->via('GET')
            ->to(controller => 'authen', action => 'authen_logout');
        
        $r->route('/dashboard')
            ->via('GET')
            ->over(authenticated => 1)
            ->to(controller => 'base', action => 'dashboard');
    }
    
    sub daemon {
        my ($class,$config) = @_;
        $config ||= {};
        $config->{port} //= 5000;
        
        my $psgi = Mojo::Server::PSGI->new( app => $class->new );
        my $app = $psgi->to_psgi_app;
        
        my $server = Twiggy::Server->new(
            #host => 'localhost',
            port => $config->{port},
        );
        $server->register_service($app);
    }
}

1;