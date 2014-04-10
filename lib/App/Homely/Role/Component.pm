# ============================================================================
package App::Homely::Role::Component;
# ============================================================================
use utf8;

use namespace::autoclean;
use Moose::Role;

sub moniker {
    my ($class) = @_;
    
    my $moniker = ref($class) || $class;
    
    $moniker =~ s/^\Q__PACKAGE__\E:://;
    $moniker =~ s/::/_/g;
    $moniker = lc($moniker);
    
    return $moniker;
}

1;