package App::Homely::Role::State::Ephermal {
    use 5.016;
    
    use Moose::Role;
    requires qw(get_state max_state_age fetch_state);
    
    has 'state_age' => (
        is              => 'rw',
        isa             => 'Int',
        predicate       => 'has_state_age',
    );
    
    around 'get_state' =>sub {
        my $orig = shift;
        my $self = shift;
        
        if ($self->has_state_age
            && $self->state_age + $self->max_state_age < time) {
            return $self->fetch_state;
        }
        
        return $self->$orig(@_);
    };
    
    after 'fetch_state' => sub {
        my ($self) = @_;
        $self->state_age(time);
        $self->store;
    };
    
    sub init_state {
        my ($class) = @_;
        my $self = $class->new;
        $self->fetch_state();
        return $self;
    }
}

1;