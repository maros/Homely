package App::Homely::State::Time {
    use 5.014;
    use warnings;
    
    use Moose;
    extends qw(App::Homely::State);
    with qw(App::Homely::Role::State::Ephermal);
    
    use Log::Any qw($log);
    
}