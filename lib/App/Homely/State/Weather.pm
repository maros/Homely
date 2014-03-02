package App::Homely::State::Weather {
    use 5.016;
    
    use strict;
    use warnings;
    
    use Moose;
    extends qw(App::Homely::State);
    with qw(App::Homely::Role::State::Ephermal);
    
    use Log::Any qw($log);
    use Weather::Underground;
    
    has 'temperature' => (
        is              => 'rw',
        isa             => 'Num',
    );
    
    has 'sunrise' => (
        is              => 'rw',
        isa             => 'DateTime',
    );
    
    has 'sunset' => (
        is              => 'rw',
        isa             => 'DateTime',
    );
    
    has 'conditions' => (
        is              => 'rw',
        isa             => 'Str',
    );
    
    has 'wind' => (
        is              => 'rw',
        isa             => 'Num',
    );

    has 'humidity' => (
        is              => 'rw',
        isa             => 'Num',
    );
    
    sub max_state_age {
        return 60 * 60;
    }
    
    sub fetch_state {
        my ($self) = @_;
        
        my $config              = App::Homely::Core->instance->config;   
        my $location            = $config->location;
        my $location_string     = join(', ',$location->{city},$location->{country});
        
        my $weather = Weather::Underground->new(
            place       => $location_string,
            debug       => 1,
        ) or $log->fatal("Error, could not create new weather object: $@\n");
        
        my $current = $weather->get_weather()->[0];
        
        use Data::Dumper;
        {
          local $Data::Dumper::Maxdepth = 2;
          warn __FILE__.':line'.__LINE__.':'.Dumper($weather);
        }
        
        $self->temperature($current->{temperature_celsius});
        $self->wind($current->{wind_kilometersperhour});
        $self->humidity($current->{humidity});
        $self->conditions($current->{conditions});
        $self->sunset(_parse_time($current->{sunset}));
        $self->sunrise(_parse_time($current->{sunrise}));
        
        return $self;
    }
    
    sub _parse_time {
        my ($string) = @_;
        
        if ($string =~ /^(\d+):(\d+)\s(AM|PM)\s\w+$/) {
            my $now = DateTime->now;
            my $time = $now->clone->set( hour => ($3 eq 'PM' ? $1+12:$1), minute => $2 );
            if ($now > $time) {
                $time->add(days => 1);
            }
            return $time;
        } else {
            #$log->error()
        }
    }
};

1;