package App::Homely::State {
    use 5.016;
    
    use strict;
    use warnings;
    
    use Moose;
    use MooseX::Storage;
    with qw(App::Homely::Role::Singelton);
    with Storage('format' => 'JSON', 'io' => 'File');
    
    use Log::Any qw($log);
    
    sub fetch_state;
    
    sub get_state {
        my ($class) = @_;
        if (blessed $class) {
            return $class;
        } else {
            return $class->load($class->_state_file) || $class->new();
        }
    }
    
    
    sub _state_file {
        my ($class) = @_;
        return Homely::Core->instance->config_dir->file($class->moniker.'.json')
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