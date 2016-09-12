#!/usr/bin/env ruby

# VMS_COPY_SLASHLOG.RB

lno = 0
%x{ COPY sys$login:login.com sys$scratch:*.com_copy /LOG }.lines do | p |
  lno += 1
  STDOUT.puts p     # display it & count it...
end
puts "counted #{lno} lines"
