#!/bin/bash
strace -e trace=file starman --workers=1 --listen=:9000 /app.psgi 2>&1 | grep -v ENOENT