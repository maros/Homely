package App::Homely::Role::State::Temporary {
    use 5.014;
    
    use Moose::Role;
    with qw(App::Homely::Role::State::Stored);
    requires qw(max_state_age);
    
    has 'state_age' => (
        is              => 'rw',
        isa             => 'Int',
        default         => sub { time },
        #isa             => 'DateTime',
        #default         => sub { DateTime->now( time_zone => 'floating' ) },
    );
    
    around 'get_state' =>sub {
        my $orig = shift;
        my $self = shift;
        
        $self = $self->$orig(@_);
        
        if ($self->state_age + $self->max_state_age < time) {
            $self = $self->new();
            $self->store();
        }
        return $self;
    };
}

1;