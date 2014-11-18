#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# dir.rb
#
# Copyright © 2011-2014 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v4.6 (11/17/2014)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# ==========

# === For command-line arguments & options parsing: ===
require 'optparse'        # See "Pickaxe v1.9", p. 776

# === File directory listing, VMS-style: ===
require 'time'
require 'pp'
require_relative 'lib/TermChar'
require_relative 'lib/DirectoryVMS'
require_relative 'lib/DateCalc'

# === Main ===
options = { :about    => false,
            :bytesize => false,
            :before   => false,
            :debug    => DBGLVL0,
            :full     => false,
            :grand    => false,
            :hidden   => false,
            :larger   => false,
            :owner    => false,
            :smaller  => false,
            :since    => false,
            :recurse  => false,
            :reverse  => false,
            :times    => false,
            :verbose  => false
          }  # hash for all com-line options;
  # see http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
  # and http://ruby.about.com/od/advancedruby/a/optionparser.htm ;
  # also see "Pickaxe v1.9", p. 776

optparse = OptionParser.new { |opts|
  opts.on( "-b", "--bytesize", "List file sizes in bytes (default is K, M, G, etc.)" ) do |val|
    options[:bytesize] = true
  end  # -b --bytesize
  opts.on( "-B", "--before [DATE]", "List files modified before date" ) do |val|
    val = "today" if ! val
    options[:before] = DateCalc.thisday( val )
  end  # -B --before
  opts.on( "-f", "--full", "Display full listing (include times and ownership)" ) do |val|
    options[:full] = options[:owner] = options[:times] = true
  end  # -f --full
  opts.on( "-g", "--grand", "Display grand totals (summarize files and sizes)" ) do |val|
    options[:grand] = true
  end  # -g --grand
  opts.on( "-H", "--hidden", "Display hidden files (filenames beginning with '.')" ) do |val|
    options[:hidden] = true
  end  # -H --hidden
  opts.on( "-l", "--larger SIZE", "List files larger than size",
           Integer ) do |val|
    options[:larger] = val
  end  # -l --larger
  opts.on( "-o", "--owner", "List file ownership 'User:Group (uid,gid)'" ) do |val|
    options[:owner] = true
  end  # -o --full
  opts.on( "-s", "--smaller SIZE", "List files smaller than size",
           Integer ) do |val|
    options[:smaller] = val
  end  # -s --smaller
  opts.on( "-S", "--since [DATE]", "List files modified since date" ) do |val|
    val = "today" if ! val
    options[:since] = DateCalc.thisday( val )
  end  # -S --since
  opts.on( "-r", "--reverse", "Display listing in reverse-sorted order" ) do |val|
    options[:reverse] = true
  end  # -r --reverse
  opts.on( "-R", "--recurse", "Recurse the listing into subdirectories" ) do |val|
    options[:recurse] = true
  end  # -R --recurse
  opts.on( "-t", "--times", "List file access and create times (atime, ctime)" ) do |val|
    options[:times] = true
  end  # -t --times
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
  end  # -a --about
  # --- Set the banner & Help option ---
  opts.banner = "\n  Usage: #{PROGNAME} options [ . | directory... ]" +
                "\n\n   where directory is the folder/directory to list.\n\n"
  opts.on_tail( "-?", "-h", "--help", "Display this help text" ) do |val|
    $stdout.puts opts
    options[:help] = true
  end  # -? --help
}.parse!  # leave residue-args in ARGV

###############################
if options[:debug] >= DBGLVL3 #
  require 'pry'               #
  binding.pry                 #
end                           #
###############################

pp options if options[:debug] >= DBGLVL2
pp ARGV    if options[:debug] >= DBGLVL1

exit true if options[:about] or options[:help]

# Set-up for terminal dimensions, especially varying width:
termwidth = TermChar.terminal_width

# Completely empty args will be nil here, so ensure first entry is "" instead:
ARGV[0] ||= ""
args = ARGV.reverse  # gonna use pop/push discipline (right-end of array)
vmsdir = DirectoryVMS.new( termwidth, options )
vmsdir.listing( args )

# exit
