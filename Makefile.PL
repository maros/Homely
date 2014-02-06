# Load the Module::Install bundled in ./inc/
use strict;
use inc::Module::Install 1.05;

my $from = 'lib/TEMPLATE-PATH';

# Define metadata
name            'TEMPLATE-NAME';
all_from        $from;
readme_from     $from;

perl_version    '5.008';

# Specific dependencies
requires        'Moose'                         => '0.94';
requires        'parent'                        => 0;

requires        'Mojolicious'                   => 0;
requires        'EV'                            => 0;
requires        'AnyEvent'                      => 0;
requires        'Log::Any'                      => 0;
requires        'Log::Any::Adapter'             => 0;



# Weather::Underground
# Inline::C
# DateTime::Event::Sunrise
# DateTime
# DateTime::Format::ICal
# Log::Any
# Log::Dispatch
# JSON::XS

# Mojolicious
# Plack
# Twiggy
# AnyEvent

# AnyEvent::XMPP
# Sms::Send

# http://www.derkalender.at/ics/derkalender_at_2014_v1a.ics



build_requires  'Test::Most'                    => 0;
build_requires  'Test::NoWarnings'              => 0;

author_requires 'Test::Pod'                     => '1.14';
author_requires 'Test::Pod::Coverage'           => '1.04';
author_requires 'Test::Perl::Critic'            => 0;
author_requires 'Module::Install::ReadmeFromPod'=> 0;

repository 'git://github.com/maros/TEMPLATE-NAME.git';

WriteAll;