#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# xchart.rb
#
# Copyright © 2012-2014 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.7 (11/19/2014)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

require 'optparse'
require 'pp'
require_relative 'lib/ANSIseq'
require_relative 'lib/TermChar'

# ==========

def display( extext, clr = :black, termwidth = 80 )
  print ''.clearscreen
  puts '-' * termwidth
  print extext.bold.color(clr)
  puts '-' * termwidth
end  # display

# ==========

ExceptionChart = <<EOD
Object
  •---Exception  # Never "rescue Exception"! (surprising results)
        •        # If a general/generic is needed, "rescue => e"
        • fatal (used internally by Ruby)
        •---NoMemoryError
        •---ScriptError
              •---LoadError
              •---NotImplementedError
              •---SyntaxError
        •---SecurityError ¹
        •---SignalException
              •---Interrupt
        •---StandardError
              •---ArgumentError
              •---FiberError ²
              •---IndexError
                    •---KeyError ²
                    •---StopIteration ²
              •---IOError
                    •---EOFError
              •---LocalJumpError
              •---NameError
                    •---NoMethodError
              •---RangeError
                    •---FloatDomainError
              •---RegexpError
              •---RuntimeError
              •---SystemCallError ³
              •---ThreadError
              •---TypeError             Notes: ¹ Was a StandardError in Ruby 1.8
              •---ZeroDivisionError            ² New in Ruby 1.9
        •---SystemExit                         ³ System-dependent exceptions
        •---SystemStackError ¹                   (Errno::xxx)
EOD

ExceptionExamples = <<EOD
  ...
  begin                                      def method_name( args, ... )
    # statement(s)...                          # statement(s)...
  rescue [ exception➀ ][ => e ]              rescue [ exception➀ ][ => e ]
    # Code to handle exception➀...             # Code to handle exception➀...
    pp e                                       pp e
    print e.backtrace.join( "\\n" )             print e.backtrace.join( "\\n" )
  rescue [ exception➁ ][ => e ]              rescue [ exception➁ ][ => e ]
    # Code to handle exception➁...             # Code to handle exception➁...
  else                                       else
    # If no exception occurs in the            # If no exception occurs in the
    # begin/end block, then this               # method block, then this code
    # code block is executed...                # block is executed...
  ensure                                     ensure
    # Code to be executed no matter            # Code to be executed no matter
    # what happens in the begin/end            # what happens in the method
    # block: run if the block runs             # block: run if the block runs
    # to completion, or if it throws           # to completion, or if it throws
    # an exception...                          # an exception, or if the method
  end                                          # executes a return statement...
                                           end
EOD

# ==========

options = { :color   => "black",
            :verbose => false,
            :debug   => DBGLVL0,
            :about   => false
          }

optparse = OptionParser.new { |opts|
  opts.on( "-c", "--color", "=String",
           /black|white|red|green|blue|purple|brown|cyan|yellow/i,
           "Output text in this color" ) do |val|
    options[:color] = val.downcase
  end  # -c --color
  opts.on( "-e", "--ech", "--hierarchy", "--chart",
           "Display Ruby Exception Class Hierarchy" ) do |val|
    options[:ech] = true
  end  # -e --ech
  opts.on( "-x", "--examples", "Display Ruby Exception (rescue) examples" ) do |val|
    options[:examples] = true
  end  # -e --examples
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
  opts.banner = "\n  Usage: #{PROGNAME} [options]\n\n"
  opts.on_tail( "-?", "-h", "--help", "Display this help text" ) do |val|
    $stdout.puts opts
    options[:help] = true
    exit true
  end  # -? --help
}.parse!  # leave residue-args in ARGV

###############################
if options[:debug] >= DBGLVL3 #
  require 'pry'               #
  binding.pry                 #
end                           #
###############################

color = options[:color] ? options[:color].to_sym : :black

# Set-up for terminal dimensions:
termheight = TermChar.terminal_height
termwidth  = TermChar.terminal_width

# ===========

options[:ech] = true if !options[:examples]

display( ExceptionChart, color, termwidth ) if options[:ech]

display( ExceptionExamples, color, termwidth ) if options[:examples]
