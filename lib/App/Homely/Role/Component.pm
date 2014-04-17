# ============================================================================
package App::Homely::Role::Component;
# ============================================================================
use utf8;

use namespace::autoclean;
use Moose::Role;
#requires qw(init);

use Log::Any qw($log);

sub moniker {
    my ($class) = @_;
    
    my $moniker = ref($class) || $class;
    
    $moniker =~ s/^App::Homely::[^:]+:://;
    $moniker =~ s/::/_/g;
    $moniker = lc($moniker);
    
    return $moniker;
}

sub init_components {
    my ($class) = @_;
    
    # Load states
    my $mpo = Module::Pluggable::Object->new(
        search_path => [ $class ],
    );
    
    my %loaded;
    foreach my $component_class ($mpo->plugins) {
        $log->debug('Try to component '.$component_class);
        my ($ok,$error) = Class::Load::try_load_class($component_class);
        unless ($ok) {
            $log->error('Could not load component '.$component_class.': '.$error);
            next;
        } else {
            $log->info('Loaded component '.$component_class->moniker);
            $loaded{$component_class->moniker} = $component_class->init();
        }
    }
    return \%loaded;
}

1;