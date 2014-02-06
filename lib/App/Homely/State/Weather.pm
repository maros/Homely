package App::Homely::State::Weather {
    use 5.016;
    
    use strict;
    use warnings;
    
    use Moose;
    #extends qw(App::Homely::State);
    with qw(App::Homely::Role::State::Ephermal);
    
    use Log::Any qw($log);
    use Weather::Underground;
    
    sub get_state {
        my ($self) = @_;
        
        warn $self->config->location;
        
        my $weather = Weather::Underground->new(
            place       => $self->config->location,
            debug       => 1,
        ) or $log->fatal("Error, could not create new weather object: $@\n");
        
        return $weather->get_weather()->[0]
    }
}

1;