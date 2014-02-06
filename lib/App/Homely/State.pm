package App::Homely::State {
    use 5.016;
    
    use strict;
    use warnings;
    
    use Moose;
    
    use Log::Any qw($log);
    
    has 'config' => (
        is              => 'rw',
        isa             => 'App::Homely::Config',
        required        => 1,
    );
    
}

1;