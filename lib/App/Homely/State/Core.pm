package App::Homely::State::Presence {
    use 5.016;
    
    use warnings;
    
    use Moose;
    extends qw(App::Homely::State);
    with qw(App::Homely::Role::State::Permamanent);
    
    use Log::Any qw($log);
    
    has 'mode' => (
        is              => 'rw',
        isa             => 'App::Homely::Type::Mode',
    );
    
    has 'manual_scene' => (
        is              => 'rw',
        isa             => 'Str',
    );
};

1;