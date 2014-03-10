package App::Homely::Role::State::Stored {
    use 5.016;
    use warnings;
    
    use Moose::Role;
    with qw(App::Homely::Role::Storage);
    
    sub get_state {
        my ($class) = @_;
        if (blessed $class) {
            return $class;
        } else {
            my $file = $class->storage_filename;
            if (-e $file) {
                return $class->load();
            } else {
                my $self = $class->new();
                $self->store();
                return $self;
            }
        }
    }
}

1;