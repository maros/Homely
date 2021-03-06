package App::Homely::State {
    use 5.014;
    
    use warnings;
    
    use Moose;
    with qw(App::Homely::Role::Singelton
        App::Homely::Role::Component);

    use Log::Any qw($log);
}

1;