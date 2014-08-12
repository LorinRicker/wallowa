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
  PROGID = "#{PROGNAME} v4.1 (08/11/2014)"
  AUTHOR = "Lorin Ricker, Franktown, Colorado, USA"

# === For command-line arguments & options parsing: ===
require 'optparse'        # See "Pickaxe v1.9", p. 776

# === File directory listing, VMS-style: ===
require 'time'
require 'pp'
require_relative 'TermChar'
require_relative 'DirectoryVMS'
require_relative 'DateCalc'
require_relative 'Diagnostics'

# === Main ===
options = { :about    => false,
            :bytesize => false,
            :before   => false,
            :debug    => false,
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

optparse = OptionParser.new do |opts|
  # Set the banner:
  opts.banner = "Usage: #{PROGNAME} options [ . | ... | directory | directory... ]"
  opts.on( "-?", "-h", "--help", "Display this help text" ) do |val|
    puts opts
    options[:help] = true
  end  # -? --help
  opts.on( "-a", "--about", "Display program info" ) do |val|
    puts "#{PROGID}"
    puts "#{AUTHOR}"
    options[:about] = true
  end  # -a --about
  opts.on( "-b", "--bytesize", "List file sizes in bytes (default is K, M, G, etc.)" ) do |val|
    options[:bytesize] = true
  end  # -b --bytesize
  opts.on( "-B", "--before [DATE]", "List files modified before date" ) do |val|
    val = "today" if ! val
    options[:before] = DateCalc.thisday( val )
  end  # -B --before
  opts.on( "-d", "--debug", "Display debug information" ) do |val|
    options[:debug] = true
  end  # -d --debug
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
  opts.on( "-v", "--verbose", "Verbose mode" ) do |val|
    options[:verbose] = true
  end  # -v --verbose
end  #OptionParser.new
optparse.parse!  # leave residue-args in ARGV

pp options if options[:debug]
pp ARGV    if options[:debug]

exit true if options[:about] or options[:help]

# Set-up for terminal dimensions, especially varying width:
termwidth = TermChar.terminal_width
puts "width: #{termwidth}" if options[:debug]

# Completely empty args will be nil here, so ensure first entry is "" instead:
ARGV[0] ||= ""
args = ARGV.reverse  # gonna use pop/push discipline (right-end of array)
vmsdir = DirectoryVMS.new( termwidth, options )
vmsdir.listing( args )

# exit
