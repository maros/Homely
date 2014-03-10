package App::Homely::State {
    use 5.016;
    
    use warnings;
    
    use Moose;
    with qw(App::Homely::Role::Singelton);

    use Log::Any qw($log);
    
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