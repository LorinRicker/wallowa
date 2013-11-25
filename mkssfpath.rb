#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# lsfunction.rb
#
# Copyright © 2012 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.02 (11/24/2013)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

# === For command-line arguments & options parsing: ===
require 'optparse'        # See "Pickaxe v1.9", p. 776
require 'pp'
require_relative 'Prompted'

# ==========

options = {}  # hash for all com-line options;
  # see http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
  # and http://ruby.about.com/od/advancedruby/a/optionparser.htm ;
  # also see "Pickaxe v1.9", p. 776

optparse = OptionParser.new do |opts|
  # Set the banner:
  opts.banner = "Usage: #{PROGNAME} [options] working_directory srchost [env_var_name]"
  opts.on( "-?", "-h", "--help", "Display this help text" ) do |val|
    puts opts
    options[:help] = true
    exit true
  end  # -? --help
  opts.on( "-a", "--about", "Display program info" ) do |val|
    puts "#{PROGID}"
    puts "#{AUTHOR}"
    options[:about] = true
    exit true
  end  # -a --about
  opts.on( "-v", "--verbose", "Verbose mode" ) do |val|
    options[:verbose] = true
  end  # -v --verbose
end  #OptionParser.new
optparse.parse!  # leave residue-args in ARGV

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
