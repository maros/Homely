package App::Homely::Role::State::Permanent {
    use 5.016;
    
    use Moose::Role;
    with qw(App::Homely::Role::State::Stored);
}

1;