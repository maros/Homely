package App::Homely::Core {
    use 5.016;
    
    use Moose;
    with qw(App::Homely::Role::Common
        App::Homely::Role::Singelton);
    
    use App::Homely::Config;
    use App::Homely::Logger;
    use App::Homely::Web;
    
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
    
    has 'states' => (
        is              => 'rw',
        isa             => 'HashRef[App::Homely::State]',
        traits          => ['Hash'],
        handles         => {
            get_state       => 'get',    
        },
        
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
        
#        # Check loop
#        my $timer = AnyEvent->timer(
#            after   => 1, 
#            interval=> 30, 
#            cb      => sub {  
#                $self->check;
#            }
#        );
        
        # Register states
        $self->init_states();
        
        # Start webserver
        App::Homely::Web->daemon();
       
        $log->info('Start event loop');
           
        # Loop event
        $cv->recv;
        
        $log->info('Finish event loop');
    
        $self->finish();
    }
    
    sub finish {
        my ($self) = @_;
        # callback for plugins
    }
    
    sub check {
        my ($self) = @_;
        # callback for plugins
        say('CHECK');
    }
    
    sub init_states {
        my ($self) = @_;
        
        # Load states
        my $mpo = Module::Pluggable::Object->new(
            search_path => [ 'App::Homely::State' ],
        );
        
        
        my $states = {};
        foreach my $state_class ($mpo->plugins) {

            my ($ok,$error) = Class::Load::try_load_class($state_class);
            unless ($ok) {
                $log->error('Could not load '.$state_class.': '.$error);
                next;
            } else {
                $log->info('Loaded state '.$state_class->moniker);
            }
            
            $states->{$state_class->moniker} = $state_class->get_state();
        }
        
        return $states;
    }
    
    sub _build_timezone {
        my ($self) = @_;
        return DateTime::TimeZone->new( name => $self->config->get('timezone'));
    }
}

1;