#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# mkssfpath.rb
#
# Copyright © 2012-2017 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.6 (02/16/2015)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

require 'optparse'
require 'pp'
require_relative 'lib/Prompted'

# ==========

options = { :verbose => false,
            :debug   => DBGLVL0,
            :about   => false
          }

ARGV[0] = '--help' if ARGV.size == 0  # force help if naked command-line

optparse = OptionParser.new { |opts|
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
  opts.banner = "\n  Usage: #{PROGNAME} [options] working_directory srchost [env_var_name]\n\n"
  opts.on_tail( "-?", "-h", "--help", "Display this help text" ) do |val|
    $stdout.puts opts
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

# Build an environment-variable (VMS "logical name") command script which
# creates a path definition for a remote directory path corresponding to
# the local current default directory path; that absolute local path is
# provided in command-line ARGV[0]...

localpath = ARGV[0]
srchost   = ARGV[1].chomp
logname   = ARGV[2] != "" ? ARGV[2] : "rd"  # the remote directory...

tarhost = srchost == "music" ? getprompted( "Remote node", "honeybee" ) : "music"

$stderr.puts ">>> '#{srchost}'   '#{tarhost}'" if options[:verbose]

# First, disassemble the local path so that its top-level directory
# components can be replaced with the top-path to the equivalent
# remote directory path:

localdirs = localpath.split( File::SEPARATOR )

# Simple replacement rules; see ~/com/mount-sshfs.sh for correspondences:
#   "/home"           with "/media/sshfs"
#   "/usr"            with "/media/sshfs"
#   ".../lorin/..."   with ".../musicLorin/..."
#   ".../Mirrors/..." with ".../musicMirrors/..."
localdirs[1] = case localdirs[1]
                 when "home" then "media/sshfs"
                 when "usr"  then "media/sshfs"
                 # when "«+»" then "«+»"
               end  # case localdirs[1]
localdirs[2] = case localdirs[2]
                 when "lorin"   then "#{tarhost}Lorin"
                 when "Mirrors" then "#{tarhost}Mirrors"
                 when "dixie"   then "#{tarhost}Dixie"
                 # when "«+»" then "#{tarhost}«+»"
               end  # case localdirs[2]

remotepath = localdirs.join( File::SEPARATOR )

if options[:verbose]
  puts "localpath, localdirs, remotepath:"
  pp localpath
  pp localdirs
  pp remotepath
end  # if options[:verbose]

if ! Dir.exists?( remotepath )
  $stderr.puts "%#{PROGNAME}-E-NOPATH, directory #{remotepath} not available"
  exit false
end  # if ! Dir.exists?( remotepath )

begin

  scriptfile = "/home/lorin/scratch/mkssfpath#{$$}.tmp"
  File.open( scriptfile, "w" ) do | f |
    f.puts "\#!/usr/bin/env bash"
    f.puts ""
    f.puts "\# Temp-Script to declare/export a Remote Working-Directory"
    f.puts "\# environment variable (like a VMS logical name)..."
    f.puts "\# Generate both UP/lo-case versions..."
    f.puts ""
    f.puts "deflogical \"#{logname.downcase}\" \"#{remotepath}\""
    f.puts "logicals #{logname.downcase}"
    f.puts ""
  end  # File.open

  File.chmod( 0700, scriptfile )  # Make it executable...

  $stdout.puts "#{scriptfile}"    # Tell calling-script the name
                                  # of the scriptfile to execute...

rescue IOError
  $stderr.puts "%#{PROGNAME}-IOError, cannot open file #{scriptfile}"
  exit false
end
