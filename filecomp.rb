#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# filecomp.rb
#
# Copyright © 2011-2017 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v4.5 (06/29/2015)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# ==========

# YADT := Yet Another Diff-Tool:
# -----------------------------
# The EXEC_TOOLS are command-line utilities which can (must)
#   be invoked with the Kernel.exec method (which "chain-invokes"
#   that exec'd program, does not return to this caller).
# The CANDIDATE_TOOLS gives the list of _possible_ diff-tools
#   which _may_ be used from this script -- all possible and
#   tested/verified utilities useful in this context.
# The residue-set CANDIDATE_TOOLS - EXEC_TOOLS is that set of
#   diff-tools which will be launched with the Kernel.spawn
#   method as independent GUI/window tools.
#
# >>> Update one or both of these constants if/when you add YADT!   <<<
# >>> Also be sure to update the help-text for OptionParse's --help <<<
     EXEC_TOOLS = %w{ cmp dhex diff }
CANDIDATE_TOOLS = EXEC_TOOLS + %w{ diffuse fldiff kdiff3 kompare meld }
  DIRDIFF_TOOLS = %w{ dirdiff }

  # Note: tried 'hexdiff', but found it too buggy to use...
  #       but 'dhex' is usable for hex diffing (and editing).

require 'optparse'
require_relative 'lib/FileComparison'
require_relative 'lib/filemagic'
require_relative 'lib/FileEnhancements'
require_relative 'lib/Prompted'
require_relative 'lib/ANSIseq'
require_relative 'lib/TermChar'

# === Main ===

options = { :tool    => 'meld',
            :dirdiff => nil,
            :digest  => "SHA256",
            :width   => nil,
            :verbose => false,
            :debug   => DBGLVL0,
            :about   => false
          }

optparse = OptionParser.new { |opts|
  # --- Program-Specific options ---
  opts.on( "-s", "--digest[=DIGEST]", /SHA1|SHA256|SHA384|SHA512|MD5|R.*MD160/i,
           "Message digest (SHA256 (d), SHA384, SHA512, R[IPEMD]160,",
           "  or MD5 or SHA1 (both deprecated as insecure)" ) do |val|
  options[:digest] = val || "SHA256"
  end  # -s --digest
  opts.on( "-m", "--dependency", "Dependency (files' mtimes) mode" ) do |val|
    options[:dependency] = true
  end  # -m --dependency
  opts.on( "-t", "--times", "Include file times (mtime, atime, ctime)" ) do |val|
    options[:times] = true
  end  # -t --times
  opts.on( "-D", "--dirdiff", "Launch the \"dirdiff\" tool (displayed in a separate",
                              "window before file comparison operations)" ) do |val|
    options[:dirdiff] = true
  end  # -D --dirdiff
  opts.on( "-u", "--tool=TOOL", "--use", "Which diff-tool to use" ) do |val|
    options[:tool] = val.downcase
  end  # -u --use --tool
  opts.on( "-w", "--width=WIDTH", "Terminal display width" ) do |val|
    options[:width] = val.to_i
  end  # -w --width
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
  opts.banner = "\n  Usage: #{PROGNAME} [options] file1 file2           (form #1)"   +
                "\n         where file1 is compared to file2."                       +
                "\n\n     or: #{PROGNAME} [options] file [file...] dir    (form #2)" +
                "\n         where any filespec can be wildcarded"                    +
                "\n         when the last argument is a directory."                  +
                "\n\n     Differences can be reported and displayed with a GUI file-comp tool.\n\n"
  opts.on_tail( "-?", "-h", "--help", "Display this help text" ) do |val|
    $stdout.puts opts
    $stdout.puts "\n    --dirdiff (-D) optionally launches the \"dirdiff\" GUI application to display"
    $stdout.puts "    differences between the (different) file1 and file2 directories.  To launch"
    $stdout.puts "    dirdiff, the last command-line argument must be a directory."
    $stdout.puts "\n    --use=TOOL (--tool=TOOL or -u) let's you specify your favorite file comparison"
    $stdout.puts "    tool for comparing two files or file-versions."
    $stdout.puts "\n    filecomp knows about several *nix command-line and GUI/windows tools, including:"
    $stdout.puts "    #{CANDIDATE_TOOLS.to_s}."
    $stdout.puts "\n    Of these, #{EXEC_TOOLS.to_s} are command-line tools; the remainder are"
    $stdout.puts "    GUI/windows tools."
    $stdout.puts "\n    Nearly all of these tools (except \"diff\") are optional, and must be manually"
    $stdout.puts "    installed on your system.  Any diffie-tools not installed will not appear in"
    $stdout.puts "    the prompt-line to invoke the diff-tool; the program that you specify with the"
    $stdout.puts "    --tool option will appear as the [default] choice in that prompt, ready for use."
    exit true
  end  # -h --help
}.parse!  # leave residue-args in ARGV

###############################
if options[:debug] >= DBGLVL3 #
  require 'pry'               #
  binding.pry                 #
end                           #
###############################

options[:width] ||= TermChar.terminal_width
stat = false
lastarg = ARGV[-1] || ''  # completely empty args will be nil, ensure "" instead

if File.directory?( lastarg )
  if ARGV.size == 1
    $stderr.puts "%#{PROGNAME}-e-usage, first argument must be a file, not a directory"
    exit false
  end
  # Command form is: $ filecomp file [file...] dir/
  # Optionally launch directory-diff tool against directory of first arg and lastarg:
  if options[:dirdiff]
    dir1 = File.expand_path( File.dirname( ARGV[0] ) )
    launch_dirdiff( dir1, lastarg, options )
  end
  dir = ARGV.pop
  ARGV.each do | arg |
    Dir.glob( arg ).each do | f |
      next if File.directory?( f )
      d    = File.inherit_basename( f, dir )
      stat = fileComparison( f, d, options )
    end
  end
else
  if ARGV.size > 2
    $stderr.puts "%#{PROGNAME}-e-usage, last argument must be a directory"
    exit false
  end
  # Command form is: $ filecomp file1 [file2]
  f1 = ARGV[0] || ""
  f2 = ARGV[1] || ""
  wilderr = "%#{PROGNAME}-e-wildcards, no wildcards allowed"
  if f1 == ""
    # The prompt-loop-continuous mode:
    while ( f1 = getprompted( "file1", f1 ) )
      exit false if File.wildcarded?( f1, wilderr )
      f2 = getprompted( "file2", f2 )
      exit false if File.wildcarded?( f2, wilderr )
      # In this interactive mode, >do not< replace the string that the user has
      # entered with full filespec, so that f2 can be reused as next default:
      fc   = File.inherit_basename( f1, f2 )
      stat = fileComparison( f1, fc, options )
    end # while
  else
    # The do-once-then-exit (command-line) mode:
    # Got the first file f1, prompt for the second file f2 if not provided:
    f2   = getprompted( "file2", f2 ) if f2 == ""
    exit false if File.wildcarded?( f2, wilderr )
    f2   = File.inherit_basename( f1, f2 )
    stat = fileComparison( f1, f2, options )
  end  # if f1 == ""
end

exit stat
