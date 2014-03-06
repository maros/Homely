package App::Homely::State {
    use 5.016;
    
    use strict;
    use warnings;
    
    use Moose;
    use MooseX::Storage;
    with qw(App::Homely::Role::Singelton);
    with Storage('format' => 'JSON', 'io' => 'File');
    
    use Log::Any qw($log);
    
    sub get_state {
        my ($class) = @_;
        if (blessed $class) {
            return $class;
        } else {
            my $file = $class->_state_file->stringify;
            if (-e $file) {
                return $class->load();
            } else {
                my $self = $class->new();
                $self->store();
                return $self;
            }
        }
    }
    
    sub moniker {
        my ($class) = @_;
        
        my $moniker = ref($class) || $class;
        
        $moniker =~ s/^\Q__PACKAGE__\E:://;
        $moniker =~ s/::/_/g;
        $moniker = lc($moniker);
        
        return $moniker;
    }
}

1;