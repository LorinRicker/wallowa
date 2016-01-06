#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# mdrender.rb
#
# Copyright © 2016 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# Inspired by:
# http://stackoverflow.com/questions/7694887/is-there-a-command-line-utility
#                                    -for-rendering-github-flavored-markdown

# This makes a nice pipeline with htmldoc (installed separately):
#   $ mdrender README.md > T.htmldoc && \
#        hdmldoc T.html -f T.pdf -t pdf14 --textfont sans --webpage && \
#        evince T.pdf
# Note that htmldoc is not particularly sdtin/out redirection-friendly,
#   so we use intermediate files (it is a Windows program too)...
#
# See:
#   $ man hdmldoc
# and:
#   $ evince /usr/share/doc/htmldoc/htmldoc.pdf &

# -----

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v0.2 (01/06/2016)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

# -----

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# ==========

require 'optparse'
require 'pp'
require 'github/markdown'

# ==========

options = { :noop        => true,  # nil,
            :verbose     => false,
            :debug       => DBGLVL0,
            :about       => false
          }

optparse = OptionParser.new { |opts|
  opts.on( "-n", "--dryrun", "Test (rehearse) «·»" ) do |val|
    options[:noop] = true
  end  # -n --dryrun
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
  opts.banner = "\n  Usage: #{PROGNAME} [options]"
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

options[:verbose] = options[:debug] >= DBGLVL1

puts GitHub::Markdown.render_gfm File.read(ARGV[0])
