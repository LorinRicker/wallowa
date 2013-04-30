#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# «·».rb
#
# Copyright © 2012 Lorin Ricker <lorin@rickernet.us>
# Version 0.1, «·»/«·»/2012
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require 'optparse'        # See "Pickaxe v1.9", p. 776
# require 'optparse/time'   #
# require 'ostruct'         #                   , p. 778
# require 'pp'              #                   , p. 780
require 'readline'        #                   , p. 788
include Readline          #
require 'abbrev'          #                   , p. 720

COMMANDS = %w{ XXX command words here }
  ABBREV = COMMANDS.abbrev
Readline.completion_proc = proc do |string|
  ABBREV[string]
  end  # proc

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v0.«·» («·»/«·»/2012)"
  AUTHOR = "Lorin Ricker, Franktown, Colorado, USA"

def getprompted( pstr, dstr )
  # "remembers" the last value entered by user
  # and offers it as the current default...
  begin
    prompt = pstr + ( dstr ? " [#{dstr}]: " : ": " )
    inp = readline( prompt, true )
    return ( inp != "" ? inp : dstr )
  rescue StandardError
    exit true  # this exit always provides cmd-line status:0
  end
end #getprompted

# === Main ===
options = {}  # hash for all com-line options;
  # see http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
  # and http://ruby.about.com/od/advancedruby/a/optionparser.htm ;
  # also see "Pickaxe v1.9", p. 776

optparse = OptionParser.new do |opts|
  # Set the banner:
  opts.banner = "Usage: #{PROGNAME} [options]      # Ctrl/D to exit"
  opts.on( "-h", "-?", "--help", "Display this help text" ) do |val|
    puts opts
    exit true  # status:0
  end  # -h
  opts.on( "-a", "--about", "Display program info" ) do |val|
    puts "#{PROGID}"
    #~ exit true   # ...depends on desired program behavior
  end  # -a
  opts.on( "-v", "--verbose", "Verbose mode" ) do |val|
    options[:verbose] = true
  end  # -v
#  opts.on( "-«·»", "--«·»", "Description-«·»" ) do |val|
#    options[:«·»] = «·»
#  end  # -«·»
end  #OptionParser.new
optparse.parse!  # leave residue-args in ARGV

f1 = ARGV[0] || ""  # a completely empty args will be nil here, ensure "" instead
f2 = ARGV[1] || ""

# === The utility process itself: ===
while ( sstr = getprompted( "«·»-prompt-string", sstr ) )
  # ...process...
end # while

# exit
