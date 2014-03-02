package App::Homely::Config {
    use 5.016;
    use warnings;
    
    use Moose;
    
    use Log::Any qw($log);
    use JSON::XS;
    
    foreach my $key (qw(web location states utits)) {
        has $key => (
            is              => 'rw',
            isa             => 'HashRef',
            default         => sub { return {} }
        );
        
    }
    
    sub load {
        my ($class,$location) = @_;
        
        unless (-e $location) {
            die 'Could not load config file at '.$location;
        }
        
        my $slurped = Path::Class::File
            ->new($location)
            ->slurp( iomode => '<:encoding(UTF-8)' );
            
        my $config = JSON::XS
            ->new
            ->utf8
            ->decode($slurped);
        
        return $class->new($config);
    }
}

1;