@echo off
echo Launching k4freeserver...
set path=c:\ruby191\bin;c:\ruby192\bin;c:\ruby193\bin;%path%
cd src
ruby k4freeserver.rb --v