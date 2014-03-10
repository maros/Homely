# ============================================================================
package App::Homely::Role::Scene::TemperatureControl;
# ============================================================================
use utf8;

use namespace::autoclean;
use Moose::Role;

sub target_temperature {
    my ($self) = @_;
    
    my $core            = App::Homely::Core->instance;
    my $day_temp        = $core->config->get('temperature/day');
    my $night_temp      = $core->config->get('temperature/max');
    
    my $outside_temp    = $core->get_state('weather')->temperature;
    my $outside_temp    = $core->get_state('time')->temperature;
    
    my $time_now        = DateTime->now();
    
    if ($temperature > )
}

1;