package App::Homely::Core {
    use 5.014;
    
    use Moose;
    with qw(App::Homely::Role::Common
        App::Homely::Role::Singelton);
    
    use App::Homely::Config;
    use App::Homely::Logger;
    use App::Homely::Web;
    use App::Homely::Connector;
    use App::Homely::State;
    
    
    use DateTime;
    use AnyEvent;
    use Log::Any qw($log);
    use MooseX::Types::Path::Class;
    
    has 'config' => (
        is              => 'rw',
        isa             => 'App::Homely::Config',
        default         => sub {
            my ($self) = @_;
            return App::Homely::Config->load($self->config_file);
        }
    );
    
    has 'timezone' => (
        is              => 'ro',
        isa             => 'DateTime::TimeZone',
        lazy_build      => 1,
    );
    
    sub run {
        my ($self) = @_;
        
        $log->info('Initalize Homely');
        
        # Initalize condvar
        my $cv = AnyEvent->condvar;
        
        # Signal handler
        my $term_signal = AnyEvent->signal(
            signal  => "TERM", 
            cb      => sub { 
                $log->info('Recieved TERM signal');
                $cv->send;
            }
        );
        my $int_signal = AnyEvent->signal(
            signal  => "INT", 
            cb      => sub { 
                $log->info('Recieved INT signal');
                $cv->send;
            }
        );
#        my $die_signal = AnyEvent->signal(
#            signal  => "__DIE__", 
#            cb      => sub { 
#                $log->error('Recieved DIE signal');
#                $cv->send;
#            }
#        );
        
        # Check loop
        my $timer = AnyEvent->timer(
            after   => 1, 
            interval=> 30, 
            cb      => sub {  
                $self->check;
            }
        );
        
        # Register components
        App::Homely::Connector->init_components();
        App::Homely::State->init_components();
        
        # Start webserver
        App::Homely::Web->daemon();
        
        # Init connectors
       
        $log->info('Start event loop');
           
        # Loop event
        $cv->recv;
        
        $log->info('Finish event loop');
    }
    
    sub check {
        my ($self) = @_;
        # callback for plugins
        say('CHECK');
    }
    
    sub _build_timezone {
        my ($self) = @_;
        return DateTime::TimeZone->new( name => $self->config->get('location/timezone'));
    }
}

1;