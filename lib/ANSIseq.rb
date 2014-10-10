#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# ANSIseq.rb
#
# Copyright © 2011-2014 Lorin Ricker <Lorin@RickerNet.us>
# Version 2.0, 10/09/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# To render ANSI-escape-sequence effects on a compliant terminal(-emulator),
# such as a VT2xx, VT3xx, VT4xx, VT5xx-series or an X-term, use the following
# String methods:
#
#   str = 'string'.color(:red)
#   or...
#   puts "This is a test.".bold
#
# Or even in combinations, as long as the color attribute comes last
# (which is an ANSI-escape-sequence rendition limitation):
#
#   str = 'string'.bold.color(:red)
#   or...
#   puts "This is a test.".bold.underline.color(:purple)

class String

# ANSI terminal rendition control-sequences:
      ESC = ?\033
     NORM = "[0m"  # normal rendition
     BOLD = "[1m"  # bold
     ULIN = "[4m"  # underline
     RVRS = "[7m"  # reverse

   CLRSCR = "[H[2J"  # ANSI terminal clear-screen

# Colors:
    BLACK = "[0;30m"
      RED = "[0;31m"
    GREEN = "[0;32m"
    BROWN = "[0;33m"
     BLUE = "[0;34m"
   PURPLE = "[0;35m"
     CYAN = "[0;36m"
   LTGRAY = "[0;37m"
   DKGRAY = "[1;30m"
    LTRED = "[1;31m"
  LTGREEN = "[1;32m"
   YELLOW = "[1;33m"
   LTBLUE = "[1;34m"
 LTPURPLE = "[1;35m"
   LTCYAN = "[1;36m"
    WHITE = "[1;37m"

def render( rendition )
  # Copy the object string (self) for testing, trim trailing whitespace,
  # test end-of-string characters so that only a single instance of NORM
  # is appended, then return the entire original string wrapped with
  # begin/end-rendition ANSI-escape-sequences:
  begin
    str  = self
    tstr = str.rstrip
    ln   = NORM.length
    str  = str + NORM unless tstr[-ln,ln] == NORM
    return rendition + str
  rescue
    return self
  end
end  # render

def bold
  self.render( BOLD )
end  # bold

def underline
  self.render( ULIN )
end  # underline

def reverse
  self.render( RVRS )
end  # reverse

# Render *any* of the available colors here;
# common colors each have their own method:
def color( colour )
  rendition = case colour.to_sym
              when :black    then BLACK
              when :red      then RED
              when :green    then GREEN
              when :brown    then BROWN
              when :blue     then BLUE
              when :purple   then PURPLE
              when :cyan     then CYAN
              when :ltgray   then LTGRAY
              when :dkgray   then DKGRAY
              when :ltred    then LTRED
              when :ltgreen  then LTGREEN
              when :yellow   then YELLOW
              when :ltblue   then LTBLUE
              when :ltpurple then LTPURPLE
              when :ltcyan   then LTCYAN
              when :white    then WHITE
              else
                $stderr.puts "%ANSIseq-W-nocolor, requested color not supported"
                BLACK
              end  # case colour
  self.render( rendition )
end  # color

def clearscreen
  return $stdout.tty? ? CLRSCR : ""
end  # clearscreen

end  # class String

# === Main/test/demo ===
if $0 == __FILE__
  puts "\n#{'='*3} ANSI color demo #{'='*30}"
  colors = [ :black, :white,
             :red, :ltred, :blue, :ltblue, :green, :ltgreen,
             :purple, :ltpurple, :cyan, :ltcyan, :dkgray, :ltgray,
             :yellow, :brown ]
  x = "ABC.xyz!"
  colors.each do | c |
    cs = c.to_s
    ps = sprintf( "%10s: '%s' - '%s' - '%s'", cs, x.color(c),
                       x.bold.color(c), cs.underline.color(c) )
    puts ps
  end
  puts "#{'='*50}"
end
