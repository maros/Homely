package App::Homely::Role::Singelton {
    use 5.016;
    
    use utf8;
    
    use namespace::autoclean;
    use Moose::Role;
    
    our %INSTANCES;
    
    sub BUILD {
        my ($self) = @_;
        
        my $class = ref($self) || $self;
        if ( defined $INSTANCES{$class} ) {
            die 'There is already an '.$class.' instance';
        }
        $INSTANCES{$class} = $self;
        return $self;
    }
    
    sub instance {
        my ($class) = @_;
        return $INSTANCES{$class} || $class->new();
    }
}

1;