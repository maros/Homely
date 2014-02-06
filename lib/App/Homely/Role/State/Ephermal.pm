package App::Homely::Role::State::Ephermal {
    use 5.016;
    
    use Moose::Role;
    requires qw(get_state max_state_age);
    
    has 'state_age' => (
        is              => 'rw',
        isa             => 'Int',
        predicate       => 'has_state_age',
    );
    
    around 'get_state' =>sub {
        my $orig = shift;
        my $self = shift;
        
        if ($self->has_state_age) {
            
        }
        
        return $self->$orig(@_);
    };
}

1;