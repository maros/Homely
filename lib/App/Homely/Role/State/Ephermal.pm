package App::Homely::Role::State::Ephermal {
    use 5.014;
    
    use Moose::Role;
    
    sub init {
        my ($class) = @_;
        return $class->new();
    }
}

1;