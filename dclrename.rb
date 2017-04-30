#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# dclrename.rb
#
# Copyright © 2015-2017 Lorin Ricker <lorin@rickernet.us>
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
  PROGID = "#{PROGNAME} v1.9 (04/30/2017)"
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
            :case        => nil,
            :whitespace  => nil,
            :fnprefix    => nil,  # filename prefix text
            :fnsuffix    => nil,  # filename suffix text
            :xtprefix    => nil,  # file extension prefix text
            :xtsuffix    => nil,  # file extension suffix text
            :force       => false,
            :verbose     => false,
            :debug       => DBGLVL0,
            :about       => false
          }

usage = "    Usage: $ #{PROGNAME} [options] file [file...] " +
        "'rename_pattern'".bold

optparse = OptionParser.new { |opts|
  opts.on( "-c", "--case=fixup",
              /lower|upper|capital|camel|snake/i,
           "Convert target filename case, " + "fixup".underline + " is one of:",
           "  " + "lower".underline + ", " + "UPPER".underline + ", " +
                  "Capital".underline + ",",
           "  " + "camel".underline + " (CamelCase), " +
                  "snake".underline + " (snake_case)" ) do | val |
             options[:case] = val.downcase.to_sym
             options[:force]   = true
  end  # -c --case
  opts.on( "-w", "--whitespace=fixup",
             /underscores|spaces|compress|collapse/i,
          "Convert target filename whitespace, " + "fixup".underline + " is one of:",
           "  " + "underscores".underline + " (' ' to '_'),",
           "  " + "spaces".underline + " ('_' to ' '),",
           "  " + "compress".underline + " (multi-runs of ' ', '_' or '-'",
           "    to single instances of that character),",
           "  " + "collapse".underline + " all spaces away" ) do |val|
    options[:whitespace] = val.downcase.to_sym
    options[:force]   = true
  end  # -w --whitespace
  opts.on( "--nameprefix='PREFIXSTR'",
           "(rename only) Concatenate PREFIXSTR onto",
           "the beginning of the filename (basename)" ) do |val|
    options[:fnprefix] = val.to_str
  end  # --nameprefix
  opts.on( "--namesuffix='SUFFIXSTR'",
  "(rename only) Concatenate SUFFIXSTR onto",
  "the end of the filename (basename)" ) do |val|
    options[:fnsuffix] = val.to_str
  end  # --namesuffix
  opts.on( "--extprefix='PREFIXSTR'",
           "(rename only) Concatenate PREFIXSTR onto",
           "the beginning of the file's extension" ) do |val|
    options[:xtprefix] = val.to_str
  end  # --exteprefix
  opts.on( "--extsuffix='SUFFIXSTR'",
           "(rename only) Concatenate SUFFIXSTR onto",
           "the end of the file's extension" ) do |val|
    options[:xtsuffix] = val.to_str
  end  # --extsuffix
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
    require_relative 'lib/AboutProgram'
    options[:about] = about_program( PROGID, AUTHOR, true )
  end  # -a --about
  # --- Set the banner & Help option ---
  opts.banner = "\n#{usage}" +
                "\n\n    where 'rename_pattern' is either a destination directory or a" +
                "\n    wildcard pattern such as '.../path/*.*', 'fname.*' or '*.ext'," +
                "\n    and quotes '' or \"\" are necessary to prevent globbing.\n\n"
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

pp options[:fnprefix]
pp options[:fnsuffix]
pp options[:xtprefix]
pp options[:xtsuffix]

if ARGV.length < 2
  $stderr.puts "%#{PROGNAME}-f-args, insufficient arguments"
  $stderr.puts "#{usage}"
  exit false
end

$stdout.puts "%#{PROGNAME}-i-noop, dry-run..." if options[:noop]

dcloptions, operands = DCLcommand.parse_dcl_qualifiers( ARGV )
options.merge!( dcloptions )
DCLcommand.rename( options, operands )

exit true
