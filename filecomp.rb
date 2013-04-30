#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# filecomp.rb
#
# Copyright © 2011-2012 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v2.4 (10/24/2012)"
  AUTHOR = "Lorin Ricker, Franktown, Colorado, USA"

# === For command-line arguments & options parsing: ===
require 'optparse'        # See "Pickaxe v1.9", p. 776

require_relative 'FileComparison'
require_relative 'FileEnhancements'
require_relative 'Prompted'
require_relative 'ANSIseq'

def askKompare( f1, f2, kopt )
  launch = askprompted( "Launch Kompare on these files" ) if ! kopt
  if launch || kopt
    puts "launching Kompare..."
    # launch Kompare as child/subproc; it's noisey on startup, so discard stderr...
    spawn( "kompare 2>/dev/null \"#{f1}\" \"#{f2}\"" )
  end  # if launch || kopt
end  # askLaunch

def report( stat, f1, f2, options )
  sep = stat ? "==".bold.color(:green) : "<>".bold.color(:red)
  puts "'#{f1}' #{sep} '#{f2}'"
  askKompare( f1, f2, options[:kompare] ) if ! stat
  # User will exit getprompted() with Ctrl-D or Ctrl-Z,
  # which _always_exits_with_ status:0 ...
end  # report

# === Main ===
options = {}  # hash for all com-line options;
  # see http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
  # and http://ruby.about.com/od/advancedruby/a/optionparser.htm ;
  # also see "Pickaxe v1.9", p. 776

optparse = OptionParser.new do |opts|
  # Set the banner:
  opts.banner = "Usage: FileComp [options] [file1] [file2]"
  opts.on( "-h", "-?", "--help", "Display this help text" ) do |val|
    puts opts
    exit true
  end  # -h --help
  opts.on( "-a", "--about", "Display program info" ) do |val|
    puts "#{PROGID}"
    puts "#{AUTHOR}"
    exit true   # -- depends on desired program behavior
  end  # -a --about
  opts.on( "-m", "--digest", "=[OPT]", /SHA1|SHA256|SHA384|SHA512|MD5/i,
           ## %w{ SHA1 SHA256 SHA384 SHA512 MD5 sha1 sha256 sha385 sha512 md5 },
           "Message digest type (SHA1 (d), SHA[256,384,512] or MD5)" ) do |val|
  options[:digest] = val || "SHA1"
  end  # -m --digest
  opts.on( "-d", "--dependency", "Dependency (files mtime) mode" ) do |val|
    options[:dependency] = true
  end  # -d --dependency
  opts.on( "-t", "--times", "Include file times (mtime, atime, ctime)" ) do |val|
    options[:times] = true
  end  # -t --times
  opts.on( "-k", "--kompare", "Launch Kompare to see diff-details" ) do |val|
    options[:kompare] = true
  end  # -k --kompare
  opts.on( "-v", "--verbose", "Verbose mode" ) do |val|
    options[:verbose] = true
  end  # -v --verbose
end  #OptionParser.new
optparse.parse!  # leave residue-args in ARGV

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
