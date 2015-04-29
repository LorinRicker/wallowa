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
  PROGID = "#{PROGNAME} v0.5 (04/29/2015)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

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
require 'pp'

require_relative 'lib/ANSIseq'
require_relative 'lib/TermChar'
require_relative 'lib/FileEnhancements'  # includes AppConfig class

# ==========

def cmdRename( operands, options )
  # operands is an array, e.g. ARGV (or a derived subset thereof)

  opts = options.dup.delete_if { |k,v| FUOPTS.find_index(k).nil? }

  termwidth = TermChar.terminal_width

  # decompose the rename pattern
  repat     = File.expand_path( operands.pop )  # last argument is the rename pattern
  repatdirn = File.directory?( repat ) ? repat + '/' : File.dirname( repat )
  repattype = File.extname( repat )
  repatname = File.basename( repat, repattype )
  options[:namewild] = repatname.index( WILDSPLAT )
  options[:typewild] = repattype.index( WILDSPLAT )
  begin
    $stdout.puts "\nrename-pattern: '#{repat}'"
    pp( operands, $stdout )
    pp( opts, $stdout )
    pp( options, $stdout )
  end if options[:debug] > DBGLVL0

  # TODO: parse any '*.ext' or 'fname.*' and
  #       set options[:namewild] &/or options[:typewild]
  #       accordingly...
  #       OR? This can be a pattern -> gsub() ???

  operands.each_with_index do | f, idx |
    src     = File.expand_path( f )
    srcdirn = File.dirname( src )
    srctype = File.extname( src )
    srcname = File.basename( src, srctype )

    dstname  = options[:namewild] ? srcname : repatname
    dstname += options[:typewild] ? srctype : repattype
    if File.directory?( repat )
      dst = File.join( repatdirn, "#{srcname + srctype}" )
    else
      dst = File.join( repatdirn, dstname )
    end
    if File.exists?( dst ) && ! options[:force]
      m1 = "%#{PROGNAME}-e-noclobber, "
      m2 = "file '#{dst}' already exists;"
      m3 = "use --force (-F) to supersede it"
      if m1.size + m2.size + m3.size < termwidth
        msg = m1 + m2 + ' ' + m3
      else
        msg = m1 + m2 + "\n" + ' '*m1.size + m3
      end
      $stderr.puts msg
    else
      $stdout.puts "file \##{idx+1}: '#{src}' --> '#{dst}'" if options[:debug] > DBGLVL0
      FileUtils.mv( src, dst, opts )
    end
  end  # operands.each

end  # cmdRename

# === Main ===
FUOPTS  = [ :force, :noop, :preserve, :verbose ] # options-set for FileUtils...
options = { :namewild => false,
            :typewild => false,
            :noop     => false,
            :force    => false,
            :verbose  => false,
            :debug    => DBGLVL0,
            :about    => false
          }

usage = "    Usage: $ #{PROGNAME} [options] file [file...] " +
        "'rename_pattern'".bold

optparse = OptionParser.new { |opts|
  opts.on( "-f", "--filenamewild", "--namewild",
           "Retain the file#{"name".underline} part of the source filespec" ) do |val|
    options[:namewild] = true
  end  # -f --filenamewild
  opts.on( "-t",  "--typewild","--filetypewild",
           "Retain the file#{"type".underline} part of the source filespec" ) do |val|
    options[:typewild] = true
  end  # -t --typewild
  opts.separator ""
  opts.on( "-F", "--force",
           "Force rename to replace existing files" ) do |val|
    options[:force] = true
  end  # -F --force
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
  opts.banner = "\n#{usage}" +
                "\n\n    where 'rename_pattern' is either a destination directory or a" +
                "\n    wildcard pattern such as '.../path/*.*', 'fname.*' or '*.ext';" +
                "\n    quotes '' may be needed to prevent globbing.\n\n"
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

$stdout.puts "%#{PROGNAME}-i-noop, dry-run..."
cmdRename( ARGV, options )

exit true
