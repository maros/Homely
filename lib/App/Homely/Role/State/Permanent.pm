package App::Homely::Role::State::Permanent {
    use 5.016;
    
    use Moose::Role;
    
    sub init_state {
        my ($class) = @_;
        my $self = $class->new;
        # TODO
        return $self;
    }
}

1;