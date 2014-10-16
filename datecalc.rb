#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# datecalc.rb
#
# Copyright © 2012-2014 Lorin Ricker <lorin@rickernet.us>
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require 'optparse'        # See "Pickaxe v1.9", p. 776
require 'pp'
require_relative 'lib/DateCalc'
require_relative 'lib/ANSIseq'

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.2 (10/15/2014)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

# === Main ===
options = {}  # hash for all com-line options;
  # see http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
  # and http://ruby.about.com/od/advancedruby/a/optionparser.htm ;
  # also see "Pickaxe v1.9", p. 776

optparse = OptionParser.new { |opts|
  opts.on( "-v", "--verbose", "Verbose mode" ) do |val|
    options[:verbose] = true
  end  # -v
  opts.on( "-a", "--after", "=N", Integer, "N".underline + " days after " + "date".underline + " is " + "<DATE>".bold ) do |val|
    options[:after] = val
  end  # -A
  opts.on( "-b", "--before", "=N", Integer, "N".underline + " days before " + "date".underline + " is " + "<DATE>".bold ) do |val|
    options[:before] = val
  end  # -B
  opts.on( "-t", "-w", "--between", "=DATE", "N days".bold + " between " + "date".underline + " and " + "date".underline ) do |val|
    options[:between] = val
  end  # -b
  opts.on( "-u", "--until", "=DATE", "N days".bold + " between " + "today".underline + " and " + "date".underline ) do |val|
    options[:until] = val
  end  # -u
#  opts.on( "-«·»", "--«·»", "Description-«·»" ) do |val|
#    options[:«·»] = «·»
#  end  # -«·»
  # Set the banner:
  opts.banner = "Usage: #{PROGNAME} options [date1 [date2]]"
  opts.on( "-h", "-?", "--help", "Display this help text" ) do |val|
    puts opts
    exit true  # status:0
  end  # -h
  opts.on( "-a", "--about", "Display program info" ) do |val|
    puts "#{PROGID}"
    exit true   # ...depends on desired program behavior
  end  # -a
}.parse!  # leave residue-args in ARGV

if !ARGV[0]
  ARGV << DateCalc.thisday( "today" ).to_s  # push the default if empty
else
  ARGV[0] = DateCalc.thisday( ARGV[0] ).to_s
end  # if !ARGV[0]
pp ARGV if options[:verbose]

# ARGV[0] (n_days) days after options[:after] (date) is...
DateCalc.days_after( options[:after], ARGV[0], true ) if options[:after]

# ARGV[0] (n_days) days before options[:before] (date) is...
DateCalc.days_before( options[:before], ARGV[0], true ) if options[:before]

# The number of days between ARGV[0] and options[:between] (dates) is...
DateCalc.days_between( ARGV[0], options[:between], true ) if options[:between]

# from "today" until options[:until] (date) is ??? days...
DateCalc.days_until( options[:until], true ) if options[:until]

# exit
