#!/usr/bin/env ruby

# VMS_SHOWSYS.RB

lno = 0
%x{ SHOW SYSTEM }.lines do | p |
  lno += 1
  STDOUT.puts p     # display it & count it...
end
puts "counted #{lno} lines"
