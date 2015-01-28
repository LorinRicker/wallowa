#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# argvdemo.rb
#
# Copyright © 2012-2015 Lorin Ricker <lorin@rickernet.us>
# Version info: see PROGID below
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# Demonstrate bash command-line globbing and command switch handling, e.g.:
#   $ ruby ARGVdemo -h
#   $ ruby ARGVdemo -a
#   $ ruby ARGVdemo -v --owner
#   $ ruby ARGVdemo --larger=123
#   $ ruby ARGVdemo --since=today
#   $ ruby ARGVdemo *.rb            # <- globbing
#   $ ruby ARGVdemo $rby/*.rb
#   $ ruby ARGVdemo *.rb $rby/*.txt
#   $ ruby ARGVdemo *.txt *.rb
#   $ ruby ARGVdemo '*.txt' "*.rb"  # <- watch quoted behavior re: globbin
#

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v0.6 (01/27/2015)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

require 'optparse'
require 'optparse/date'
require 'optparse/time'
require 'pp'
require_relative 'lib/ANSIseq'

def message( phase, msg, render = :green )
  msg = "=== " + phase + " OptionParser processing === " + msg
  puts "\n#{msg.color(render)}"
end  # message

def cmdlinevalues( argv, options )
  print '   ARGV => '
  pp argv
  print 'options => '
  pp options
end  # cmdlinevalues

# === Main ===
options = { :verbose => false,
            :debug   => DBGLVL0,
            :about   => false
          }

message( "Before", "Watch cmd-line globbing behavior...", :red )
cmdlinevalues( ARGV, options )

optparse = OptionParser.new { |opts|
  opts.on( "-o", "--owner", "List file ownership 'User:Group (uid,gid)'" ) do |val|
    options[:owner] = true
  end  # -o --full
  opts.on( "-l", "--larger SIZE", "List files larger than size",
           Integer ) do |val|
    options[:larger] = val
  end  # -l --larger
  opts.on( "-S", "--since[=DATETIME]", "List files modified since date" ) do |val|
    val = "today" if ! val
    options[:since] = val
  end  # -S --since
  # --- Verbose option ---
  opts.on( "-v", "--verbose", "--log", "Verbose mode" ) do |val|
    options[:verbose] = true
  end  # -v --verbose
  # --- Debug option ---
  opts.on( "-d", "--debug", "=DebugLevel", Integer,
           "Show debug information (levels: 1, 2 or 3)",
           "  1 - enables basic debugging information",
           "  2 - enables advanced debugging information",
           "  3 - enables (starts) pry-byebug debugger" ) do |val|
    options[:debug] = val.to_i
  end  # -d --debug
  # --- About option ---
  opts.on_tail( "-a", "--about", "Display program info" ) do |val|
    $stdout.puts "#{PROGID}"
    $stdout.puts "#{AUTHOR}"
    options[:about] = true
    exit true
  end  # -a --about
  # --- Set the banner & Help option ---
  opts.banner = "Usage: #{PROGNAME} options"
  opts.on_tail( "-h", "-?", "--help", "Display this help text" ) do |val|
    puts opts
    exit true  # status:0
  end  # -h
}.parse!  # leave residue-args in ARGV

###############################
if options[:debug] >= DBGLVL3 #
  require 'pry'               #
  binding.pry                 #
end                           #
###############################

message( "After", "Cmd-line options have been removed..." )

puts " -- Verbosity on..." if options[:verbose]
puts " -- Ownership switch asserted, do ownership processing --" if options[:owner]
puts " -- Larger (size) switch asserted, integer value: #{options[:larger]}" if options[:larger]
puts " -- Since (date) switch asserted, date value: '#{options[:since]}'" if options[:since]

cmdlinevalues( ARGV, options )

exit true
