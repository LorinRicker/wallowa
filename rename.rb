#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# rename.rb
#
# Copyright © 2015 Lorin Ricker <lorin@rickernet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

#
# See also the GNU Tools 'rename' (/usr/bin/rename), aka 'prename',
#   and "man rename" for info about a similar perl-based utility!
#

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v0.3 (04/24/2015)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

   CONFIGDIR = File.join( ENV['HOME'], ".config", PROGNAME )
  CONFIGFILE = File.join( CONFIGDIR, "#{PROGNAME}.yaml.rc" )

WILDSPLAT = '*'
WILDQUEST = '?'

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

require 'optparse'
require 'fileutils'

require_relative 'lib/ANSIseq'
require_relative 'lib/FileEnhancements'  # includes AppConfig class

# ==========

def cmdRename( operands, options )
  # decompose the rename pattern
  repat     = File.expand_path( operands.pop )  # last argument is the rename pattern
  repatdirn = File.dirname( repat )
  repattype = File.extname( repat )
  repatname = File.basename( repat, repattype )
  options[:namewild] = repatname.index( WILDSPLAT ) == 0
  options[:typewild] = repattype.index( WILDSPLAT ) == 0
  # TODO: parse any '*.ext' or 'fname.*' and
  #       set options[:namewild] &/or options[:typewild]
  #       accordingly...
  #       OR? This can be a pattern -> gsub() ???

  # TODO: do not clobber existing files (filenames), unless :force !!!

  # TODO: handle options[:sudo]  !!!

  operands.each_with_index do | f, idx |
    src     = File.expand_path( f )
    srcdirn = File.dirname( src )
    srctype = File.extname( src )
    srcname = File.basename( src, srctype )

    dstname  = options[:namewild] ? srcname : repatname
    dstname += options[:typewild] ? srctype : repattype
    dst      = File.join( repatdirn, dstname )
    puts "file \##{idx}: '#{src}' --> '#{dst}'"
    ## mv_f( src, dst )
  end  # operands.each

  puts "\nrename-pattern: '#{repat}'"

end  # cmdRename

# === Main ===
options = { :namewild => false,
            :typewild => false,
            :noop     => false,
            :sudo     => "",
            :update   => false,
            :verbose  => false,
            :debug    => DBGLVL0,
            :about    => false
          }

usage = "    Usage: $ #{PROGNAME} [options] file [file...] " +
        "'rename_pattern'".bold

optparse = OptionParser.new { |opts|
  opts.on( "-f", "--filenamewild", "--namewild",
           "File#{"name".bold} is wildcarded, keep this part" ) do |val|
    options[:namewild] = true
  end  # -f --filenamewild
  opts.on( "-t",  "--typewild","--filetypewild",
           "File#{"type".bold} is wildcarded, keep this part" ) do |val|
    options[:typewild] = true
  end  # -t --typewild
  opts.separator ""
 opts.on( "-S", "--sudo",
           "Run this backup/restore with sudo" ) do |val|
    options[:sudo] = "sudo"
  end  # -S --sudo
  opts.on( "-n", "--noop", "--dryrun", "--test",
           "Dry-run (test & display, no-op) mode" ) do |val|
    options[:noop]  = true
    options[:verbose] = true  # Dry-run implies verbose...
  end  # -n --noop
  opts.on( "-u", "--update", "--save",
           "Update (save) the configuration file; a configuration",
           "file is automatically created if it doesn't exist:",
           "#{CONFIGFILE}" ) do |val|
    options[:update] = true
  end  # -u --update
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
  opts.banner = "\n#{usage}" +
                "\n\n   where «+»\n\n"
  opts.on_tail( "-?", "-h", "--help", "Display this help text" ) do |val|
    $stdout.puts opts
    # $stdout.puts "«+»Additional Text«+»"
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

if ARGV.length < 2
  $stderr.puts "%#{PROGNAME}-f-args, insufficient arguments"
  $stderr.puts "#{usage}"
  exit false
end

cmdRename( ARGV, options )

exit true
