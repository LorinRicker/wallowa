#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# comprename.rb
#
# Copyright © 2012-2015 Lorin Ricker <Lorin@RickerNet.us>
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.1 (11/14/2015)"
  AUTHOR = "Lorin Ricker, Elbert County, Colorado, USA"

LISTFILE = '/home/lorin/projects/ruby/composers_rename/composers_rename.lis'

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

require 'optparse'
require 'fileutils'
require_relative 'lib/AskPrompted'
require_relative 'lib/ANSIseq'
require_relative 'lib/StringEnhancements'

def self.display_help( clr = false )
  ex1 = "RENAME Lname 'Lname, Rnames'".underline
  ex2 = "DIR:subdir".underline
  ex3 = "'Lname, Rnames'".underline
  cmd1 = "cd $rlb".bold
  cmd2 = "comprename -h".bold
  $stdout.puts String.clearscreen if clr
  $stdout.puts <<-EOT
=== #{PROGNAME} - Instructions for use ===
Purpose: Rename groups of subdirectories which are named as
         composers' last names (short-sighted) to full-name
         forms:  #{ex1}

         The text file '#{LISTFILE}' specifies:
           a) Directive line of form #{ex2} which
              changes the relative subdirectory in which
              composer-named directories are to be found
              and renamed.  For example:
              DIR:Chamber
              DIR:Orchestral
              DIR:Piano
           b) Composers' names of form #{ex3}, where
              'Lname' is the expected composer directory name
              to be found and renamed, and #{ex3} is
              the new composer directory name.
           c) Blank and comment lines (beginning with '#') are
              ignored.

    1. $ #{cmd1}
       or to other archive/backup or phone relative-top
       directory for the RipLibrary.
    2. $ #{cmd2}     # for help and these Instructions
       ...In particular, see the --dryrun and --confirm options.

  EOT
end  # display_help

options = { :confirm    => false,
            :noop       => false,
            :verbose    => false,
            :debug      => DBGLVL0,
            :about      => false
          }

optparse = OptionParser.new { |opts|
  opts.on( "-i", "--confirm", "--interactive",
           "Interactive/confirm mode" ) do |val|
    options[:confirm]  = true
  end  # -n --noop
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
  opts.banner = "\n  Usage: #{PROGNAME} [options] Display terminal characteristics\n\n"
  opts.on_tail( "-?", "-h", "--help", "Display this help text" ) do |val|
    $stdout.puts opts
    $stdout.puts
    display_help
    exit true
  end  # -? --help
}.parse!  # leave residue-args in ARGV

###############################
if options[:debug] >= DBGLVL3 #
  require 'pry'               #
  binding.pry                 #
end                           #
###############################

subdir = ""

answer = askprompted( "Is CWD '#{Dir.getwd}' correct" )
if answer
  # The script-data file 'composers_rename.lis' must be found
  # in the current working directory (copy it there, if not):
  begin
    lines = File.open( LISTFILE, "r" ).readlines
  rescue Errno::ENOENT => e
    $stderr.puts "%#{PROGNAME}-f-fnf, can't open #{LISTFILE}"
    exit false
  end
  lines.each do | line |
    line = line.chomp.compress
    # Ignore blank and comment lines:
    next if line == "" || line[0] == "#"
    # Directive line to 'change subdirectory': DIR:Piano
    sdtmp = line.split( ':' )
    if sdtmp[0] == "DIR"
      subdir = sdtmp[1]
      next
    end
    # Otherwise, got a subdirectory file to rename; the line is of the form
    #   Lname, Rnames
    # to RENAME Lname "Lname, Rnames" --
    # or in other words, the subdir formerly named "Lname"
    # is renamed to "Lname, Rnames" ...
    lname = line.split( ',' )[0]
    dir1 = File.join( subdir, lname )
    if File.directory?( dir1 )
      dir2 = File.join( subdir, line )
      ok = options[:confirm] ?
             askprompted( "Rename '#{dir1}' -> '#{dir2}' [yes,No,quit]") : true
      FileUtils.mv( dir1, dir2, :verbose => options[:verbose] ) if ok && ! options[:noop]
      puts "%#{PROGNAME}-i-rename, '#{dir1}' -> '#{dir2}'" if ok && options[:verbose]
    end
  end
else
  display_help( clr = true )
end

exit true
