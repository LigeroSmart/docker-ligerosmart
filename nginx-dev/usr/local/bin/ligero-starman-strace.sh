#!/bin/bash

# strace -e trace=file starman --workers=1 --listen=:9000 /app.psgi 2>&1 | grep -v ENOENT

strace -e trace=file -qq starman --workers=1 --listen=:9000 \
  -M Plack::Loader \
  -M Plack::Middleware::AccessLog \
  -M Starman::Server \
  -M Net::Server::PreFork \
  -M HTTP::Parser::XS \
  -M Devel::StackTrace \
  /app.psgi 2>&1 | grep -v ENOENT