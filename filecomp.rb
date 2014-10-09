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
  PROGID = "#{PROGNAME} v2.5 (10/08/2014)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

# === For command-line arguments & options parsing: ===
require 'optparse'        # See "Pickaxe v1.9", p. 776

require_relative 'FileComparison'
require_relative 'FileEnhancements'
require_relative 'Prompted'
require_relative 'ANSIseq'
require_relative 'TermChar'

def which_diff( options )
  diffs = %w{ cmp diff fldiff hexdiff kdiff3 kompare meld }
  cmds  = app_cmd_completions( diffs )
  diff  = getprompted( "Which diff-utility #{p diffs}", "kompare" )
  # «+»
end  # which_diff

def ask_diff( f1, f2, options )
  launch = askprompted( "Launch kompare/diff on these files" ) if ! options[:kompare]
  if launch || options[:kompare]
    progname, launchstr = which_diff( options )
    puts "launching #{progname}..."
    # launch the diffie-program as child/subproc; it's noisey on startup, so discard stderr...
    spawn( "kompare 2>/dev/null \"#{f1}\" \"#{f2}\"" )
    spawn( launchstr )
  end
end  # ask_diff

def report( stat, f1, f2, options )
  sep = stat ? "==".bold.color(:green) : "<>".bold.color(:red)
  puts "'#{f1}' #{sep} '#{f2}'"
  ask_diff( f1, f2, options ) if ! stat
  # User will exit getprompted() with Ctrl-D or Ctrl-Z,
  # which _always_exits_with_ status:0 ...
end  # report

# === Main ===
options = {  # hash for all com-line options:
  :digest =>  "SHA1",
  :width  =>  nil
  }

optparse = OptionParser.new { |opts|
  # --- Program-Specific options ---
  opts.on( "-m", "--digest", "=[OPT]", /SHA1|SHA256|SHA384|SHA512|MD5/i,
           ## %w{ SHA1 SHA256 SHA384 SHA512 MD5 sha1 sha256 sha385 sha512 md5 },
           "Message digest type (SHA1 (d), SHA[256,384,512] or MD5)" ) do |val|
  options[:digest] = val || "SHA1"
  end  # -m --digest
  opts.on( "-d", "--dependency", "Dependency (files' mtimes) mode" ) do |val|
    options[:dependency] = true
  end  # -d --dependency
  opts.on( "-t", "--times", "Include file times (mtime, atime, ctime)" ) do |val|
    options[:times] = true
  end  # -t --times
  opts.on( "-k", "--kompare", "Launch Kompare to see diff-details" ) do |val|
    options[:kompare] = true
  end  # -k --kompare
  opts.on( "-w", "--width", "Terminal display width" ) do |val|
    options[:width] = val.to_i
  end  # -w --width
  opts.on( "-v", "--verbose", "Verbose mode" ) do |val|
    options[:verbose] = true
  end  # -v --verbose
  # --- Set the banner & Help option ---
  opts.banner = "Usage: #{PROGNAME} [options] [file1] [file2]"
  opts.on( "-h", "-?", "--help", "Display this help text" ) do |val|
    puts opts
    exit true
  end  # -h --help
  # --- About option ---
  opts.on( "-a", "--about", "Display program info" ) do |val|
    puts "#{PROGID}"
    puts "#{AUTHOR}"
    exit true
  end  # -a --about
}.parse!  # leave residue-args in ARGV

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
