package App::Homely::State::Time {
    use 5.016;
    use warnings;
    
    use Moose;
    extends qw(App::Homely::State);
    with qw(App::Homely::Role::State::Ephermal);
    
    use Log::Any qw($log);
    
}