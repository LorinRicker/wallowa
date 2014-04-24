#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# autoinstall.rb
#
# Copyright © 2014 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# ===========
#  Description: «+»
#

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.00 04/23/2014"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

# === For command-line arguments & options parsing: ===
require 'optparse'        # See "Pickaxe v1.9", p. 776
require 'pp'
require 'fileutils'
require 'yaml'
require_relative 'ANSIseq'
require_relative 'StringEnhancements'
require_relative 'AskPrompted'

# Meta-characters in the Package Installation File (PIF):
COMMENTSYM = '#'
  FIELDSYM = ';'

# ==========

defpif = Dir.glob("./Package Installation*.list").first ||
         "./Package Installation.list"

options = {  # hash for all com-line options:
  :pif      => "#{defpif}",
  :logf     => "",
  :resetlog => false,
  :yes      => false,
  :testonly => false,
  :echoonly => false,
  :help     => false,
  :about    => false,
  :dryrun   => false,
  :debug    => false,
  :verbose  => false
  }

optparse = OptionParser.new { |opts|
  # --- Program-Specific options ---
  opts.on( "-p", "--pif", "--packagefile", "=PIF",
                 "Path to Package Installation File (PIF),",
                 "  defaults to '#{defpif}'" ) do |val|
    options[:pif] = val
  end  # -p --packagefile
  opts.on( "-l", "--logfile", "=LOGF",
                 "Log file for installation trace-output;",
                 "  if this option is not specified, the log file",
                 "  defaults to PIF path and filename with '.log'" ) do |val|
    options[:logf] = val
  end  # -l --logfile
  opts.on( "-r", "--resetlog",
                 "Resets (rolls-over) the current log file;",
                 "  renames any current log file to '*.log.{01..99}'",
                 "  and reopens a new, start-over log file" ) do |val|
    options[:resetlog] = true
  end  # -r --resetlog
  opts.on( "-y", "--yes", "--forceyes",
                 "Forces a 'Yes' response to any PIF 'ask'-prompts" ) do |val|
    options[:yes] = true
  end  # -y --yes
  opts.on( "-t", "--testonly",
                 "Test and report installed/uninstalled packages" ) do |val|
    options[:testonly] = true
  end  # -t --testonly
  opts.on( "-e", "--echoonly",
                 "Echo the parsed-PIF data only (no other actions)" ) do |val|
    options[:echoonly] = true
  end  # -e --echoonly
  # --- Set the banner & Help option ---
  opts.banner = "\nUsage: #{PROGNAME} [options]"
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
  # --- DryRun option ---
  opts.on( "-n", "--dryrun", "Dry run: don't actually install,",
                 "  just show what would be installed" ) do |val|
    options[:dryrun] = true
  end  # -n --dryrun
  # --- Debug option ---
  opts.on( "-d", "--debug", "Debug mode (more output than verbose)" ) do |val|
    options[:debug] = true
  end  # -d --debug
  # --- Verbose option ---
  opts.on( "-v", "--verbose", "Verbose mode" ) do |val|
    options[:verbose] = true
  end  # -v --verbose
}.parse!  # leave residue-args in ARGV

# Propagate a couple of implications --
options[:debug]   ||= options[:dryrun]  # ...and also debug...
options[:verbose] ||= options[:debug]   # ...and debug implies verbose
pp options if options[:debug]

# Expand and deconstruct PIF for inheritances/defaults:
pif = File.expand_path( options[:pif] )
puts " pif: '#{pif}'" if options[:debug]
pifdir  = File.dirname( pif )
pifext  = File.extname( pif )
pifbase = File.basename( pif, pifext )
STDOUT.puts " dir: '#{pifdir}'\nbase: '#{pifbase}'\n ext: '#{pifext}'" if options[:debug]

# Unless specified by options[:logf],
#  logfile inherits /...path/filename from PIF:
logf = options[:logf] == "" ? File.join( pifdir, "#{pifbase}.log" ) : options[:logf]
logf = logf + ".log" if File.extname( logf ) == ""
logf = File.join( pifdir, logf ) if File.dirname( logf ) == "."
STDOUT.puts "logf: '#{logf}'" if options[:debug]

# Test: Must be running as 'root' (sudo), else exit!

# If options[:resetlog] then rename existing log file to *.log.{01..99}
# and allow File.open( logf, "a" ) to create a new/fresh log file

# If options[:yes] then do not askprompt (of user) for "ask"-installs,
#   just do (force) them...
# If options[:testonly] then do not actually install any packages,
#   just report whether each packages is installed or not...
#
# Open LogFile for message and apt-get install output lines
# Open PIFile for input
# For each non-blank, non-comment line:
#   Split line into (3) fields on ";"
#   Test "package" for installed-status
#   if options[:testonly]
#     then test-report ("installed" or "not installed")
#     else if "package" not installed:
#       if "ppa" is specified, test and apt-get add it
#       apt-get install "package", with "ask" or options[:yes] if specified

session_sep = "=" * 60 + "\n"
install_sep = "-" * 20 + "\n"

# At this point (only), force options[:debug] if options[:echoonly] --
options[:debug] ||= options[:echoonly]

# Always "a"ppend the log-file:
File.open( logf, "a" ) do | outf |
  # Start a session-header (useful for multi-session appends):
  outf.puts "#{session_sep}  #{PROGID}\n  session-start timestamp: #{Time.now}\n"

  File.open( pif, "r" ) do | inf |
    inf.each_line do | ln |
      # Compress whitespace, trim off (ignore) comment:
      data = ln.compress.split(COMMENTSYM)
      data = data.empty? ? "" : data[0]
      STDOUT.puts ">>   data: '#{data}'"
      next if data.empty?
      package, flags, ppa = data.split(FIELDSYM).each { |fld| fld.strip! }
      STDOUT.puts "  package: '#{package}'\n    flags: '#{flags}'\n      ppa: '#{ppa}'" if options[:debug]
      next if options[:echoonly]  # just output the parsed PIF-data
      #...
    end  # inf.each_line

  end  # File.open inf

end  # File.open outf
