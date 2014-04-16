package App::Homely::Config {
    use 5.014;
    use warnings;
    
    use Moose;
    
    use Log::Any qw($log);
    use JSON::XS;
    
    has 'config' => (
        is              => 'rw',
        isa             => 'HashRef',
        default         => sub { return {} }
    );
    
    sub load {
        my ($class,$location) = @_;
        
        unless (-e $location) {
            die 'Could not load config file at '.$location;
        }
        
        my $slurped = $location
            ->slurp( iomode => '<:encoding(UTF-8)' );
            
        my $config = JSON::XS
            ->new
            ->utf8
            ->decode($slurped);
        
        return $class->new(config => $config);
    }
    
    sub get {
        my ($self,$path) = @_;
        
        my $config = $self->config;
        foreach my $part (split(/\//,$path)) {
            unless (ref($config) eq 'HASH' 
                && exists $config->{$part}) {
                $log->error('Could not find config key '.$path);
                return;
            }
            $config = $config->{$part};                
        }
        if (ref($config) eq 'HASH') {
            $log->error('Could not find config key '.$path);
            return;
        }
        
        return $config;
    }
}

1;