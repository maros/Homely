#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use 5.010;

use FindBin qw();
use lib "$FindBin::Bin/../lib";

use App::Homely::Connector::ZWave;

App::Homely::Connector::ZWave->init()->loop;

