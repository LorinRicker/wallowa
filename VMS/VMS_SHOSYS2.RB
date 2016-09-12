#!/usr/bin/env ruby

# VMS_SHOSYS2.RB

lno = 0
%x{ shosys }.lines do | p |
  lno += 1
  STDOUT.puts p     # display it & count it...
end
puts "counted #{lno} lines"
