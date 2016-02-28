#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# dclrename.rb
#
# Copyright © 2015-2016 Lorin Ricker <lorin@rickernet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

#
# See also the GNU Tools 'rename' (/usr/bin/rename), aka 'prename',
#   and "man rename" for info about a similar perl-based utility!
#

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.6 (02/28/2016)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

WILDSPLAT = '*'
WILDQUEST = '?'

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

require 'optparse'
require 'pp'

require_relative 'lib/DCLcommand'
require_relative 'lib/ANSIseq'
require_relative 'lib/ErrorMsg'
require_relative 'lib/FileEnhancements'  # includes AppConfig class

# === Main ===
options = { :noop        => false,
            :convert     => nil,
            :force       => false,
            :verbose     => false,
            :debug       => DBGLVL0,
            :about       => false
          }

usage = "    Usage: $ #{PROGNAME} [options] file [file...] " +
        "'rename_pattern'".bold

optparse = OptionParser.new { |opts|
  opts.on( "-c", "--convert=FIXUP",
              /lower|upper|capital|camel|snake|underscores|spaces|compress/i,
           "Convert target filename case:",
           "  lower, UPPER, Capital,",
           "  camel (CamelCase), snake (snake_case),",
           "  underscores (' ' to '_'), spaces ('_' to ' '),",
           "  compress (multi-runs of ' ', '_' or '-'",
           "  to single instances of that character)" ) do |val|
    options[:convert] = val.downcase.to_sym
    options[:force]       = true
  end  # -c --case
  opts.on( "-F", "--force",
           "Force rename to replace existing files" ) do |val|
    options[:force] = true
  end  # -F --force
  opts.on( "-n", "--noop", "--dryrun", "--test",
           "Dry-run (test & display, no-op) mode" ) do |val|
    options[:noop]  = true
    options[:verbose] = true  # Dry-run implies verbose...
  end  # -n --noop
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
  opts.banner = "\n#{usage}" +
                "\n\n    where 'rename_pattern' is either a destination directory or a" +
                "\n    wildcard pattern such as '.../path/*.*', 'fname.*' or '*.ext';" +
                "\n    quotes '' may be needed to prevent globbing.\n\n"
  opts.on_tail( "-?", "-h", "--help", "Display this help text" ) do |val|
    $stdout.puts opts
    # $stdout.puts "«+»Additional Text«+»"
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

if ARGV.length < 2
  $stderr.puts "%#{PROGNAME}-f-args, insufficient arguments"
  $stderr.puts "#{usage}"
  exit false
end

$stdout.puts "%#{PROGNAME}-i-noop, dry-run..." if options[:noop]

DCLcommand.rename( options, ARGV )

exit true
