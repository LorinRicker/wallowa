#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# termchar.rb
#
# Copyright © 2012-2014 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.0, 10/26/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

require 'optparse'        # See "Pickaxe v1.9", p. 776
require_relative 'lib/TermChar'

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v2.0 (10/26/2014)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

  options = {  # hash for all com-line options:
    :characters => false,
    :lines      => false,
    :help       => false,
    :about      => false,
    :debug      => false,
    :verbose    => false
    }

optparse = OptionParser.new { |opts|
  # --- Program-Specific options ---
  opts.on( "-c", "--characters", "--width",
           "Display terminal width in characters" ) do |val|
    options[:characters] = true
  end  # -c --characters --width
  opts.on( "-l", "--lines", "--length",
           "Display terminal length in lines" ) do |val|
    options[:lines] = true
  end  # -l --lines --length
  opts.on( "-g", "--geometry",   # --geometry=80x24, WxL
           "Display terminal geometry as WxL" ) do |val|
    options[:geometry] = true
  end  # -g --geometry
  # --- Set the banner & Help option ---
  opts.banner = "Usage: #{PROGNAME} [options] Display terminal characteristics"
  opts.on( "-?", "-h", "--help", "Display this help text" ) do |val|
    puts opts
    exit true
  end  # -? --help
  # --- About option ---
  opts.on( "-a", "--about", "Display program info" ) do |val|
    puts "#{PROGID}"
    puts "#{AUTHOR}"
    exit true
  end  # -a --about
  # --- Debug option ---
  opts.on( "-d", "--debug", "Debug mode (more output than verbose)" ) do |val|
    options[:debug] = true
  end  # -d --debug
  # --- Verbose option ---
  opts.on( "-v", "--verbose", "Verbose mode" ) do |val|
    options[:verbose] = true
  end  # -v --verbose
}.parse!  # leave residue-args in ARGV

case
when options[:geometry]
  s = options[:verbose] ? "%#{PROGNAME}-i-WxL, terminal geometry is " : ""
  puts "#{s}#{TermChar.terminal_width}x#{TermChar.terminal_height}"
when options[:characters]
  s = options[:verbose] ? "%#{PROGNAME}-i-width, terminal width is " : ""
  puts "#{s}#{TermChar.terminal_width} characters"
when options[:lines]
  s = options[:verbose] ? "%#{PROGNAME}-i-length, terminal length is " : ""
  puts "#{s}#{TermChar.terminal_height} lines"
else
  TermChar.terminal_dimensions( true )
end
