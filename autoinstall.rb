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
  PROGID = "#{PROGNAME} v1.00 04/24/2014"
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

SESSION_SEP = "=" * 60 + "\n"
INSTALL_SEP = "-" * 20 + "\n"

# ==========

def versioned_name( fil, ver )
  path = File.dirname( fil )
  ext  = File.extname( fil )
  base = File.basename( fil, ext )
  filb = File.join( path, "#{base}.#{ver}#{ext}" )
  return filb
end  # versioned_name

def roll_log( logf, options )
  if File.exists?( logf )
    vers = '001'
    logb = versioned_name( logf, vers )
    while File.exists?( logb ) && vers <= '999'
      logb = versioned_name( logf, vers.succ! )
    end  # while
    if (1..999).include?( vers.to_i )
      File.rename( logf, logb )
      STDOUT.puts "%#{PROGNAME}-I-RENAME, log file renamed to '#{logb}'" if options[:verbose]
    else
      STDOUT.puts "%#{PROGNAME}-F-LIMIT, log file version '#{vers}' exceeds range 001..999;"
      STDOUT.puts "  '#{logf}' not renamed."
      STDOUT.puts "  Move '#{versioned_name(logf,"*")}' files and retry..."
      exit false
    end
  end
end  # roll_log

def shell( cmd, package, ask, options )
  shelloutput = ""
  affirmative = ask ? askprompted( "Install #{package.underline}", "No" ) : true
  if options[:dryrun]
    STDOUT.puts "#{PROGNAME}] $ #{cmd.bold} ... # dry-run" if affirmative
  else
    STDOUT.puts "  ...installing #{package.underline}" if options[:verbose]
    shelloutput = %x{ #{cmd} } if affirmative  # executed only as sudo/root
  end
  return shelloutput  # array of lines...
end  # shell

def elapsed( started, ended = Time.now )
  delta = (ended - started).truncate
     hr = delta / 3600
  delta = delta % 3600
     mi = delta / 60
     se = delta % 60
  return sprintf( "%02d:%02d:%02d", hr, mi, se )
end  # elapsed

# ==========

# Default PIF is whatever's found in current working directory:
defpif = Dir.glob("./Package Installation*.list").first ||
         "./Package Installation.list"

options = {  # hash for all com-line options:
  :pif      => "#{defpif}",
  :logf     => "",
  :resetlog => nil,
  :yes      => nil,
  :testonly => nil,
  :echoonly => nil,
  :help     => nil,
  :about    => nil,
  :dryrun   => nil,
  :debug    => nil,
  :verbose  => nil
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
                 "  renames any current log file to '*.{001..999}.log'",
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
## pp options if options[:debug]

# Expand and deconstruct PIF for inheritances/defaults:
pif     = File.expand_path( options[:pif] )
pifdir  = File.dirname( pif )
pifext  = File.extname( pif )
pifbase = File.basename( pif, pifext )
## puts "pif: #{pif}"

# Unless specified by options[:logf],
#  logfile inherits /...path/filename from PIF:
logf = options[:logf] == "" ? File.join( pifdir, "#{pifbase}.log" ) : options[:logf]
logf = logf + ".log" if File.extname( logf ) == ""
logf = File.join( pifdir, logf ) if File.dirname( logf ) == "."

## STDOUT.puts " pif: '#{pif}'" if options[:debug]
## STDOUT.puts " dir: '#{pifdir}'\nbase: '#{pifbase}'\n ext: '#{pifext}'" if options[:debug]
## STDOUT.puts "logf: '#{logf}'" if options[:debug]

# Test: Unless dry-running, must be running as 'root' (sudo), else exit!
begin
  STDOUT.puts "%#{PROGNAME}-E-PRIV, only an administrator (sudoer or root) may install packages;"
  STDOUT.puts "#{" "*21}if you are an admin, prefix this command with 'sudo'..."
  exit true
end unless options[:dryrun] || ( Process.uid == 0 && Process.gid == 0 )

# If options[:resetlog] then rename existing log file to *.{001..999}.log
# and allow File.open( logf, "a" ) to create a new/fresh log file
roll_log( logf, options ) if options[:resetlog]

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

# At this point (only), force options[:debug] if options[:echoonly] --
options[:debug] ||= options[:echoonly]

# Always "a"ppend the log-file:
File.open( logf, "a" ) do | logoutf |
  # Session-header (useful for multi-session appends):
  session_start = Time.now
  logoutf.puts "#{SESSION_SEP}  #{PROGID}\n  session-start timestamp: #{session_start}\n"

  File.open( pif, "r" ) do | inf |
    inf.each_line do | ln |
      # Compress whitespace, trim off (ignore) comment:
      data = ln.compress.split(COMMENTSYM)
      data = data.empty? ? "" : data[0]
      next if data.empty?

      STDOUT.puts ">>   data: '#{data}'" if options[:debug]
      package, flags, ppa = data.split(FIELDSYM).each { |fld| fld.strip! }
      # Does "ask" appear in flags, and does options[:yes] override it?
      ask = ( flags =~ /ask/i ) || options[:yes] ? true : false    # want a real Boolean here!
      ## STDOUT.puts "  package: '#{package}'\n    flags: '#{flags}'\n      ppa: '#{ppa}'" if options[:debug]
      break if package == '[EXIT]'    # An early-out, mostly for testing
      next if options[:echoonly]      # Just output the parsed PIF-data

      cmd = "dpkg-query --show --showformat='${Package} [${Version}] ${Status}' #{package}"
      is_installed = %x{ #{cmd} }
      # Is this package not-yet-installed? If so, install it,
      # otherwise, report it as previously installed:
      ## puts "is_installed: '#{is_installed}'" if options[:debug]
      if is_installed =~ / ^No\ packages\ found\ matching\ #{package}.$ |
                           ^#{package}\ .*?ok\ not-installed$ /x

        install_start = Time.now
        logoutf.puts "\n#{INSTALL_SEP}  ...installing #{package}\n  install-start timestamp: #{install_start}\n"

        this_install = shell( "apt-get install --yes #{package}", package, ask, options )
        install_end  = Time.now

        this_install.each_line do | ln |
          STDOUT.puts ln if options[:debug]
          logoutf.puts ln   # echo all install-output lines to log file
        end  # this_install.each_line

        logoutf.puts "#{INSTALL_SEP}  install-end timestamp: #{install_end}"
        logoutf.puts "#{' '*11}elapsed time: #{ elapsed( install_start, install_end ) }"

      else
        msg = "#{package} is installed --> '#{is_installed}'"
        STDOUT.puts msg if options[:verbose]
        logoutf.puts msg
      end

    end  # inf.each_line

  end  # File.open inf

  # Session-footer:
  session_end = Time.now
  logoutf.puts "\n#{SESSION_SEP}  session-end timestamp: #{session_end}"
  logoutf.puts "#{' '*11}elapsed time: #{ elapsed( session_start, session_end ) }"

end  # File.open logoutf
