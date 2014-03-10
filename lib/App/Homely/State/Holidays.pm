package App::Homely::State::Holidays {
    use 5.016;
    
    use warnings;
    
    use Moose;
    extends qw(App::Homely::State);
    with qw(App::Homely::Role::State::Temporary);
    
    use Log::Any qw($log);
    
    use Data::ICal;
    use Data::ICal::DateTime;
    use LWP::Simple qw();
    
    sub max_state_age {
        return 60 * 60 * 24 * 30 * 6;
    }
    
    has 'events' => (
        is              => 'rw',
        isa             => 'HashRef[DateTime::Span]',
    );
    
    sub BUILD {
        my ($self) = @_;
        
        $log->info('Loading weather for your location');
        
        my $ical_data = LWP::Simple::get('https://mozorg.cdn.mozilla.net/media/caldata/AustrianHolidays.ics')
            or $log->fatal("Error, could not load ical: $@\n");
        
        my $calendar = Data::ICal->new( data => $ical_data );
        my @events = $calendar->events(
            DateTime::Span->from_datetimes( 
                start   => DateTime->now, 
                end     => DateTime->now->add(seconds => $self->max_state_age ) 
            )
        );
        
        my %events;
        foreach my $entry (@events) {
            next
                unless $entry->ical_entry_type eq 'VEVENT';
            my $start = $entry->start;
            my $end = $entry->end || $start->clone->add(days => 1);
            my $span = DateTime::Span->new( start => $start, end => $end );
        }
        
        return $self;
    }
    
#    sub _parse_time {
#        my ($string) = @_;
#        
#        if ($string =~ /^(\d+):(\d+)\s(AM|PM)\s\w+$/) {
#            my $now = DateTime->now( time_zone => 'floating' );
#            my $time = $now->clone->set( hour => ($3 eq 'PM' ? $1+12:$1), minute => $2 );
#            if ($now > $time) {
#                $time->add(days => 1);
#            }
#            return $time;
#        } else {
#            #$log->error()
#        }
#    }
};

1;