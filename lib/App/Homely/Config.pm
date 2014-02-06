package App::Homely::Config {
    use 5.016;
    use warnings;
    
    use Moose;
    
    use Log::Any qw($log);
    
    has 'location' => (
        is              => 'rw',
        isa             => 'Str',
        default         => 'Vienna, Austria',
    );
}

1;