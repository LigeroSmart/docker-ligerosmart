#!/usr/bin/perl
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# --
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

# To profile single requests, install Devel::NYTProf and start this script as
# PERL5OPT=-d:NYTProf NYTPROF='trace=1:start=no' plackup bin/cgi-bin/app.psgi
# then append &NYTProf=mymarker to a request.
# This creates a file called nytprof-mymarker.out, which you can process with
# nytprofhtml -f nytprof-mymarker.out
# Then point your browser at nytprof/index.html

use strict;
use warnings;

# use ../../ as lib location
use FindBin qw($Bin);
BEGIN { $Bin = "/opt/otrs/bin/cgi-bin"; }
use lib "$Bin/../..";
use lib "$Bin/../../Kernel/cpan-lib";
use lib "$Bin/../../Custom";

## nofilter(TidyAll::Plugin::OTRS::Perl::SyntaxCheck)

use CGI;
use CGI::Emulate::PSGI;
use Module::Refresh;
use Plack::Builder;

# Workaround: some parts of OTRS use exit to interrupt the control flow.
#   This would kill the Plack server, so just use die instead.
BEGIN {
    *CORE::GLOBAL::exit = sub { die "exit called\n"; };
}

my $App = CGI::Emulate::PSGI->handler(
    sub {

        # Cleanup values from previous requests.
        CGI::initialize_globals();

        # Populate SCRIPT_NAME as OTRS needs it in some places.
        $ENV{SCRIPT_NAME} = $ENV{PATH_INFO};

        # set RemoteAddr behind proxy
        if ( $ENV{HTTP_X_REAL_IP} ) {
            $ENV{REMOTE_ADDR} = $ENV{HTTP_X_REAL_IP};
        }

        if ( $ENV{HTTP_X_FORWARDED_FOR} ) {
            $ENV{REMOTE_ADDR} = $ENV{HTTP_X_FORWARDED_FOR};
            #($ENV{REMOTE_ADDR}) = split /\s*,/, $ENV{HTTP_X_FORWARDED_FOR};
        }

        my ( $HandleScript ) = $ENV{PATH_INFO} =~ m{/([A-Za-z\-_]+\.pl)};    ## no critic
 
        # Fallback to agent login if we could not determine handle...i
        if ( !defined $HandleScript || !-e "$Bin/$HandleScript" ) {
            $HandleScript = 'index.pl';                                   ## no critic
        }

        eval {

            # Reload files in @INC that have changed since the last request.
            Module::Refresh->refresh();
        };
        warn $@ if $@;

        my $Profile;
        my $ProfileSuffix;
        if ( $ENV{NYTPROF} && $ENV{REQUEST_URI} =~ /NYTProf=([\w-]+)/ ) {
            use Devel::NYTProf;
            $Profile = 1;
            $ProfileSuffix = $1;
            DB::enable_profile("$Bin/../../var/log/nytprof-$1.out");
        }

        # Load the requested script
        eval {
            do "$Bin/$HandleScript";
        };
        if ( $@ && $@ ne "exit called\n" ) {
            warn $@;
        }

        if ($Profile) {
            DB::finish_profile();
            system("HTMLProfileReportFor $ProfileSuffix");
            #unlink "$Bin/../../var/log/nytprof-$1.out";
        }
    },
);

# Small helper function to determine the path to a static file
my $StaticPath = sub {

    # Everything in otrs-web/js or otrs-web/skins is a static file.
    return 0 if $_ !~ m{-web/js/|-web/skins/};

    # Return only the relative path.
    $_ =~ s{^.*?-web/(js/.*|skins/.*)}{$1}smx;
    return $_;
};

# Create a Static middleware to serve static files directly without invoking the OTRS
#   application handler.
builder {
    # enable "StackTrace", force => $ENV{DEBUG_MODE};
    if ($ENV{DEBUG_MODE} eq "1") {
        enable "StackTrace", force => 1;
    }
    enable "Static",
        path        => $StaticPath,
        root        => "$Bin/../../var/httpd/htdocs",
        pass_trough => 0;
    enable "Plack::Middleware::ErrorDocument",
        403 => '/var/www/html/403.html',
        500 => '/var/www/html/50x.html',
        502 => '/var/www/html/50x.html';
    $App;
}
