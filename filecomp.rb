#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# filecomp.rb
#
# Copyright © 2011-2014 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v2.7 (11/17/2014)"
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
CANDIDATE_TOOLS = %w{ cmp dhex diff fldiff kdiff3 kompare meld }

  # Note: tried 'hexdiff', but found it too buggy to use...
  #       but 'dhex' is very nice, both for hex diffing and editing.

# === For command-line arguments & options parsing: ===
require 'optparse'        # See "Pickaxe v1.9", p. 776

require_relative 'lib/FileComparison'
require_relative 'lib/FileEnhancements'
require_relative 'lib/Prompted'
require_relative 'lib/ANSIseq'
require_relative 'lib/TermChar'

def is_app_installed?( app, options )
  response = %x{ whereis #{app} }.chomp.split(' ')
  puts "$ whereis #{app}: #{response}" if options[:verbose]
  return response[1] != nil
end  # is_app_installed?

def which_diff( options )
  # Test: is the candidate-app installed?  If so, add it to diffs array:
  diffs = []
  CANDIDATE_TOOLS.each { |c| diffs << c if is_app_installed?( c, options ) }
  # Setup readline completions vocabulary, and prompt user for "Which app?"
  difftools = app_cmd_completions( diffs )
  # Prefer the user-spec'd options[:diff] as the default diff-tool,
  # else just use kompare (if its installed) or diff (always installed)...
  if not ( defdiff = difftools[options[:diff]] )  # assignment!!
    defdiff = diffs.index('kompare') ? 'kompare' : 'diff'
  end
  diff = getprompted( "Diff-tool #{diffs.to_s.color(:dkgray)}", defdiff )
  diff = difftools[diff]  # Get fully-expanded command from hash...
  exit true if diff == "exit" || diff == "quit"
  # User could have entered "foobar" for all we know...
  # sanity-check the response -- is diff in diffs?
  if not diffs.index( diff )
    $stderr.puts "%#{PROGNAME}-e-unsupported, no such diff-tool '#{diff}'"
    exit true
  end
  case diff.to_sym  # a couple of special cases...
  when :cmp  then diff = "#{diff} -b --verbose"           # all bytes
  when :dhex then diff = "#{diff} -f ~/.dhexrc"
  when :diff then diff = "#{diff} -yW#{options[:width]}"  # parallel, width
  end  # case
  return [ diff, "/usr/bin/#{diff.downcase} 2>/dev/null" ]
end  # which_diff

def ask_diff( f1, f2, options )
  if askprompted( "Launch a diff-tool on these files" )
    progname, launchstr = which_diff( options )
    cmd = "#{launchstr} '#{f1}' '#{f2}'"
    msg = "launching #{progname.underline.color(:dkgray)}..."
    sep = ('=' * options[:width]).color(:red)
    if EXEC_TOOLS.index(progname.split(' ')[0])
      # These com-line tools can run directly in same XTerm session/context --
      puts "\n#{sep}\n#{msg}\n\n"
      exec( cmd )
    else
      # Launch these tools as child/subproc and as independent windows
      # (same as invoking from com-line, e.g.:  $ kompare & ) --
      puts msg
      spawn( cmd )
    end
  end
end  # ask_diff

def report( stat, f1, f2, options )
  sep = stat ? "==".bold.color(:cyan) : "<>".bold.color(:red)
  puts "'#{f1}' #{sep} '#{f2}'"
  ask_diff( f1, f2, options ) if ! stat
  # User will exit getprompted() with Ctrl-D or Ctrl-Z,
  # which _always_exits_with_ status:0 ...
end  # report

# === Main ===
options = { :diff    => nil,
            :digest  => "SHA1",
            :width   => nil,
            :verbose => false,
            :debug   => DBGLVL0,
            :about   => false
          }

optparse = OptionParser.new { |opts|
  # --- Program-Specific options ---
  opts.on( "-s", "--digest", "=[DIGEST]", /SHA1|SHA256|SHA384|SHA512|MD5/i,
           ## %w{ SHA1 SHA256 SHA384 SHA512 MD5 sha1 sha256 sha385 sha512 md5 },
           "Message digest type (SHA1 (d), SHA[256,384,512] or MD5)" ) do |val|
  options[:digest] = val || "SHA1"
  end  # -s --digest
  opts.on( "-m", "--dependency", "Dependency (files' mtimes) mode" ) do |val|
    options[:dependency] = true
  end  # -m --dependency
  opts.on( "-t", "--times", "Include file times (mtime, atime, ctime)" ) do |val|
    options[:times] = true
  end  # -t --times
  opts.on( "-u", "--diff-tool", "=TOOL", "Which diff-tool to use" ) do |val|
    options[:diff] = val.downcase
  end  # -t --diff-tool
  opts.on( "-w", "--width", "Terminal display width" ) do |val|
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
    $stdout.puts "\n  --diff-tool (-u) let's you specify your favorite file comparison"
    $stdout.puts "    tool for comparing two files or file-versions.  filecomp knows"
    $stdout.puts "    about several *nix command-line and GUI/windows tools, including:"
    $stdout.puts "    #{CANDIDATE_TOOLS.to_s}."
    $stdout.puts "    Of these, #{EXEC_TOOLS.to_s} are command-line tools, while"
    $stdout.puts "    the remainder are GUI/windows tools."
    $stdout.puts "\n    Nearly all of these tools (except \"diff\") are optional, and must"
    $stdout.puts "    be specifically installed on your system.  Any tools not installed"
    $stdout.puts "    will not appear in the prompt-line to invoke the diff-tool; the"
    $stdout.puts "    program that you specify with the --diff-tool switch will appear"
    $stdout.puts "    as the [default] in that prompt-line, ready for your use."
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

options[:digest] ||= "SHA1"
f1 = ARGV[0] || ""  # completely empty args will be nil here, ensure "" instead
f2 = ARGV[1] || ""

# === The utility process itself: ===
if f1 == ""
  # The prompt-loop-continuous mode:
  while ( f1 = getprompted( "file 1", f1 ) )
    f2 = getprompted( "file 2", f2 )
    f2 = File.inherit_basename( f1, f2 )
    stat = fileComparison( f1, f2, options )
    report( stat, f1, f2, options )
  end # while
else
  # The do-once-then-exit (command-line) mode:
  # Got the first file f1, conditionally prompt for the second file f2:
  f2 = getprompted( "file 2", f2 ) if f2 == ""
  f2 = File.inherit_basename( f1, f2 )
  stat = fileComparison( f1, f2, options )
  report( stat, f1, f2, options )
  xstat = stat ? true : false    # don't hand nil to exit...
  exit xstat  # true:0 (same) or false:1 (different)
end  # if f1 == ""
