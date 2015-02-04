#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# filecomp.rb
#
# Copyright © 2011-2015 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v3.1 (02/03/2015)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

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
CANDIDATE_TOOLS = EXEC_TOOLS + %w{ fldiff kdiff3 kompare meld }

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
            :digest  => "SHA1",
            :width   => nil,
            :verbose => false,
            :debug   => DBGLVL0,
            :about   => false
          }

optparse = OptionParser.new { |opts|
  # --- Program-Specific options ---
  opts.on( "-s", "--digest[=DIGEST]", /SHA1|SHA256|SHA384|SHA512|MD5/i,
           "Message digest type (SHA1 (d), SHA[256,384,512] or MD5)" ) do |val|
  options[:digest] = val || "SHA1"
  end  # -s --digest
  opts.on( "-m", "--dependency", "Dependency (files' mtimes) mode" ) do |val|
    options[:dependency] = true
  end  # -m --dependency
  opts.on( "-t", "--times", "Include file times (mtime, atime, ctime)" ) do |val|
    options[:times] = true
  end  # -t --times
  opts.on( "-u", "--tool=TOOL", "Which diff-tool to use" ) do |val|
    options[:tool] = val.downcase
  end  # -u --tool --diff-tool
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
    $stdout.puts "#{PROGID}"
    $stdout.puts "#{AUTHOR}"
    exit true
  end  # -a --about
  # --- Set the banner & Help option ---
  opts.banner = "\n  Usage: #{PROGNAME} [options] file1 file2" +
                "\n\n   where file1 is compared to file2, and any differences can be reported.\n\n"
  opts.on_tail( "-?", "-h", "--help", "Display this help text" ) do |val|
    $stdout.puts opts
    $stdout.puts "\n    --tool (-u) let's you specify your favorite file comparison tool"
    $stdout.puts "    for comparing two files or file-versions.  filecomp knows about"
    $stdout.puts "    several *nix command-line and GUI/windows tools, including:"
    $stdout.puts "    #{CANDIDATE_TOOLS.to_s}."
    $stdout.puts "    Of these, #{EXEC_TOOLS.to_s} are command-line tools, while"
    $stdout.puts "    the remainder are GUI/windows tools."
    $stdout.puts "\n    Nearly all of these tools (except \"diff\") are optional, and must be"
    $stdout.puts "    manually installed on your system.  Any diffie-tools not installed will"
    $stdout.puts "    not appear in the prompt-line to invoke the diff-tool; the program that"
    $stdout.puts "    you specify with the --tool option will appear as the [default] choice"
    $stdout.puts "    in that prompt-line, ready for your use."
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

f1 = ARGV[0] || ""  # completely empty args will be nil here, ensure "" instead
f2 = ARGV[1] || ""

# === The utility process itself: ===
if f1 == ""
  # The prompt-loop-continuous mode:
  while ( f1 = getprompted( "file1", f1 ) )
    f2 = getprompted( "file2", f2 )
    # In this interactive mode, >do not< replace the string that the user has
    # entered with full filespec, so that f2 can be reused as next default:
    fc = File.inherit_basename( f1, f2 )
    stat = fileComparison( f1, fc, options )
  end # while
else
  # The do-once-then-exit (command-line) mode:
  # Got the first file f1, prompt for the second file f2 if not provided:
  f2 = getprompted( "file2", f2 ) if f2 == ""
  f2 = File.inherit_basename( f1, f2 )
  stat = fileComparison( f1, f2, options )
  exit stat ? true : false
end  # if f1 == ""
