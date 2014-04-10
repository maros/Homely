package App::Homely::Role::State::Ephermal {
    use 5.014;
    
    use Moose::Role;
    
    sub get_state {
        my ($class) = @_;
        return $class->new();
    }
}

1;