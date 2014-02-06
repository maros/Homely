package App::Homely::Core {
    use 5.016;
    
    use App::Homely::Config;
    use App::Homely::Logger;
    use App::Homely::Web;
    
    use AnyEvent;
    use Log::Any qw($log);
    
    my $STATE_PREFIX = 'App::Homely::State';
    my ($STATES,$CONFIG);
    
    sub run {
        my ($class,%args) = @_;
        
        $log->info('Initalize Homely');
        
        # Load config
        # App::Homely::Config->load($args{config_file});
        
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
        
        # Check loop
        my $timer = AnyEvent->timer(
            after   => 1, 
            interval=> 30, 
            cb      => sub {  
                $class->check;
            }
        );
        
        # Register states
        $class->register_states();
        
        # Start webserver
        App::Homely::Web->daemon();
       
        $log->info('Start event loop');
           
        # Loop event
        $cv->recv;
        
        $log->info('Finish event loop');
    
        $class->finish();
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
    
    sub register_states {
        my ($self) = @_;
        
        # Load states
        my $mpo = Module::Pluggable::Object->new(
            search_path => [ 'App::Homely::State' ],
        );
        
        foreach my $state_class ($mpo->plugins) {
            Class::Load::try_load_class($state_class);
            
            my $state_moniker = $state_class;
            $state_moniker =~ s/^\Q$STATE_PREFIX\E:://;
            $state_moniker =~ s/::/_/g;
            $state_moniker = lc($state_moniker);
            
            $log->info('Initialize '.$state_moniker.' state');
            
            $STATES->{$state_moniker} = $state_class;
            $state_class->new();
        }
        
    }
}

1;