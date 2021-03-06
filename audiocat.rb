#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# audiocat.rb
#
# Copyright © 2012-2017 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# ===========
#  Problem: When a multi-movement music composition (sonata, etc) is ripped from
#           a CD (as ogg or mp3 files), the individual movements rip to separate,
#           individual files.  If these are simply copied over to an audio player
#           (iPod, SanDisk Sansa Clip, smartphone, etc), then that particular
#           composition is likely to be played back with movements either out-of-
#           order, or else separated by other pieces.  This happens regardless
#           of the play mode (shuffle, most-recent, playlist, genre, etc).

# Solution: Copy-concatenate the individual (separate track) movement files into
#           a single multi-movement composition file.

# Specifics --
#  Ogg Vorbis - Data elements are highly structured, file-aware, and cannot
#               simply be copy-concatenated -- well, yes they can, but c-c'd
#               files likely will not play back correctly on most players
#               (VLC does work), as most players will terminate playback when
#               they see the last-frame special bit set (as it is for each
#               individually ripped file).  Instead, the multiple files must
#               be structurally copied using oggCat.
#
#  MP3        - Data elements are "audio frames" (no file abstraction),
#               so multiple MP3 files can be copy-concatenated directly
#               (similar to $ cat m1.mp3 m2.mp3 m3.mp3 >work.mp3)...
#               the method copycat implements this directly.

# ===========
# Command Line --
#   $ audiocat [options] outfile infile1 infile2 [...]
#
#   Default input/output file type is .ogg (can omit the ".ogg" file extension);
#   use --type mp3 (or specify file extensions as ".mp3") to copy-cat MP3s.
#
#   Patterned input files can be specified as a range:
#     $ audiocat "Sonata Op 31" [options] track{1..4}
#   expands into:
#     $ audiocat [options] "Sonata Op 31" track1 track2 track3 track4

# ===========
# Reference & research --
#   http://www.vsdsp-forum.com/phpbb/viewtopic.php?f=8&t=347
#
# Install these packages --
#   vorbis-tools, oggvideotools, ruby-ogginfo, tagtool
#
# Analysis --
#   $ hexdump -Cn 1024 ogg-file
#
# See also these Ogg Vorbis tools:
#   oggCat        -- correctly copy/concatenates Ogg Vorbis (audio) files
#                    (does not simply copy-chain them...)
#   ogginfo       -- parses Ogg Vorbis files with extensive validity checking
#   vorbiscomment -- List & edit Ogg Vorbis comments (single file)
#   vorbistagedit -- batch editing of Ogg Vorbis comments with an editor (nano)
#   tagtool       -- (GUI) editing of Ogg Vorbis comments (single/multi-files)

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.8 (06/10/2017)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

   CONFIGDIR = File.join( ENV['HOME'], ".config", PROGNAME )
  CONFIGFILE = File.join( CONFIGDIR, "#{PROGNAME}.yaml.rc" )

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# ==========

require 'optparse'
require 'pp'
require 'fileutils'
require_relative 'lib/appconfig'
require_relative 'lib/filemagic'
require_relative 'lib/ANSIseq'
require_relative 'lib/FileParse'

# ==========

def config_save( opt )
  # opt is a local copy of options, so we can patch a few
  # values without disrupting the original/global hash --
  opt[:about]     = false
  opt[:debug]     = DBGLVL0
  opt[:update]    = false
  opt[:verbose]   = false
  AppConfig.configuration_yaml( CONFIGFILE, opt, true )  # force the save/update
end  # config_save

def copycat( outfile, infiles, options )
  # Copy-catenate infiles to outfile
  ifl, inf = "", ""
  ofl = File.basename outfile
  begin
    File.open( outfile, mode: "ab" ) do | outf |
      infiles.each_with_index do | infile, idx |
        ifl = File.basename infile
        # $stderr.puts "%#{PROGNAME}-I-COPYCAT, \"#{ifl}\" >> \"#{ofl}\"" if options[:verbose]
        # Inhale and exhale the whole thing...
        unless options[:dryrun]
          inf = File.open( infile, mode: "rb" )
          IO.copy_stream( inf, outf )
          inf.close
        end  # unless options[:dryrun]
      end  # infiles.each_with_index
    end  # File.open( outfile, ... )
  rescue StandardError => e
    $stderr.puts "%#{PROGNAME}-E-COPYCAT, error in copying: '#{ifl}'"
    pp e
    print e.backtrace.join( "\n" )     # Catch-all, display the unexpected...
    exit false                         # stop in our tracks
  end
end  # copycat

def renfiles( outfile, infile, options )
  $stderr.puts "%#{PROGNAME}-I-MV, rename \"#{infile}\" \"#{outfile}\"" if options[:verbose]
  FileUtils.mv( infile, outfile, { :force => true } ) unless options[:dryrun]
end  # renfiles

def delfiles( infiles, options )
  ifl = ""
  begin
    # Clean-up... remove (with permission) all of the infiles
    infiles.each do | infile |
      ifl = File.basename infile
      $stderr.puts "%#{PROGNAME}-I-RM, delete \"#{ifl}\"" if options[:verbose]
      FileUtils.rm [ infile ] unless options[:dryrun]
    end  # infiles.each
  rescue StandardError => e
    $stderr.puts "%#{PROGNAME}-E-DELFILES, error in deleting: '#{ifl}'"
    pp e
    print e.backtrace.join( "\n" )     # Catch-all, display the unexpected...
    exit true                          # stop in our tracks
  end
end  # delfiles

# ==========

options = { :help    => false,
            :type    => "mp3",
            :save    => false,
            :dryrun  => false,
            :remove  => false,
            :verbose => false,
            :debug   => DBGLVL0,
            :about   => false
          }

options.merge!( AppConfig.configuration_yaml( CONFIGFILE, options ) )
ARGV[0] = '--help' if ARGV.size == 0  # force help if naked command-line

optparse = OptionParser.new { |opts|
  opts.on( "-t", "--type", "=AUDIO", /mp3|ogg|wav/i,
           "Audio-type of files (mp3 (d), ogg, wav)" ) do |val|
    options[:type] = val.downcase || "mp3"
  end  # -t --type
  opts.on( "-n", "--dryrun", "Dry run: don't actually copy or delete files" ) do |val|
    options[:dryrun] = true
  end  # -n --dryrun
  opts.on( "-r", "--remove", "Remove (delete, default is keep) input files" ) do |val|
    options[:remove] = true
  end  # -r --remove
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
    require_relative 'lib/AboutProgram'
    options[:about] = about_program( PROGID, AUTHOR, true )
  end  # -a --about
  # --- Set the banner & Help option ---
  opts.banner = "\n  Usage: #{PROGNAME} [options] output-audio-file input-audio-file(s)" +
                "\n\n   Note: The output file is first, then two or more input files.\n\n"
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

# Propagate a couple of implications --
# (which should *not* be saved in the CONFIGFILE):
options[:remove] = false if options[:dryrun]      # dryrun always implies keep...
options[:debug]  = DBGLVL1 if options[:dryrun]    # ...and also debug...
options[:verbose] ||= options[:debug] > DBGLVL0   # ...and debug implies verbose

puts "%#{PROGNAME}-I-FTYPE, audio filetype is '#{options[:type]}'" if options[:debug] > DBGLVL0

# Update the config-file, at user's request:
config_save( options ) if options[:update]

# Working with this file-type (extension):
fext = ".#{options[:type]}"

# Output file is the _first_ filespec in the ARGV list, shifting it out:
outfile = File.expand_path( File.default_extension( ARGV.shift, fext ) )

# Expand shorthands like two- "{1..5}" and three-dot "{1...5}" (either syntax is
# allowed), surrounded by "{}", into multiple files, e.g.:
#   "Track1..5"     --> "Track1", "Track2", "Track3", "Track4", "Track5"
#   "Track 12...14" --> "Track 12", "Track 13", "Track 14",... "Track 17"
pat = Regexp.new( /^(.*?)    # any prefix (lazy)  m[1]
                  \{         #
                  ([0-9]+)   # 1 or more digits   m[2]
                  (\.{2,3})  # ".." or "..."      m[3]
                  ([0-9]+)   # 1 or more digits   m[4]
                  \}         #
                  (.*)       # any suffix         m[5]
                  /ix )      # ..."Lazy" prefix gives _all_ of the first
                             #    digits to the first integer value
infiles = []
argfiles = []

ARGV.each do | f |    # Each remaining file in ARGV is an input filespec...
  $stderr.puts "%#{PROGNAME}-I-ARGV, '#{f}'" if options[:debug] > DBGLVL0
  m = pat.match( f )
  if m   # Matched a pattern file-range "lo..hi",
         # so roll thru the file-range here...
    cur  = m[2]
    zcur = sprintf( '%03d', m[2] )
    zhi  = sprintf( '%03d', m[4] )
    while zcur <= zhi  # hi of "lo..hi"
      inf = m[1] + cur + m[5]
      inf = File.default_extension( m[1] + cur + m[5], fext )
      Dir.glob( inf ).each { |x| argfiles << x }
      cur  = cur.succ   # succ does just what we want!...
      zcur = zcur.succ
    end  # while zcur <= zhi
  else
    g = File.extname( f ) != "" ? f : "#{f}#{fext}"
    Dir.glob( g ).each { |x| argfiles << x }
  end  # if m
  # Careful -- globs with 2 or more wildcards (e.g., "*-{01..32}-*")
  #            can yield duplicate filespecs, so impose uniqueness:
end  # ARGV.each

argfiles.uniq.each { |x| infiles << x }
infcount = infiles.size
pp infiles if options[:debug] > DBGLVL0

fnflag = badflag = false
infiles.each do | inf |   # Validate each input file...
  binf = File.basename(inf)
  if File.exists?( inf )
    $stderr.puts "%#{PROGNAME}-I-INFILE, '#{binf}'" if options[:verbose]
    if ! inf.verify_magicnumber( options[:type] )
      $stderr.puts "%#{PROGNAME}-E-BADMAGIC, wrong file signature: #{binf}"
      badflag = true
    end  # if
    if inf.index( "'" )
      $stderr.puts "%#{PROGNAME}-E-BADCHAR, apostrophe == single-quote,"
      $stderr.puts " -W-RENAME, rename file to remove single-quote character(s)"
      badflag = true
    end  # if inf.index()
  else
    $stderr.puts "%#{PROGNAME}-E-FNF, file not found: #{binf}"
    fnflag = true
  end  # if File.exists?( inf )
end  # infiles.each
exit true if fnflag || badflag

$stderr.puts "%#{PROGNAME}-I-OUTFILE, '#{File.basename(outfile)}'" if options[:verbose]

if infcount == 1
  # This case devolves to just a file rename, no infiles deletion needed...
  renfiles( outfile, infiles[0], options )
  filez = "file"  # ...just one
else
  # Copy-concatenate all infiles to the single outfile, & conditionally delete infiles
  case options[:type]
  when "ogg"
    # See $ man oggCat -- Yes, output file first!
    #   1. oggCat takes no options, use simply as: $ oggCat outfile infile[,...]
    #   2. But as out/infiles will likely have embedded spaces, surround/guard
    #      with quotes, e.g.: "Nancarrow - Study 3abcde.ogg"
    #   3. oggCat barfs out noise messages "StreamMux::operator<<: Warning:
    #        packet number for stream <0> not matching: expected: nnn got 3"
    #      for each segment copied... so shunt the noise to /dev/null/ ...
    noise = options[:debug] <= DBGLVL1 ? "2>/dev/null " : nil
    cmd = "oggCat #{noise}'#{outfile}'"
    infiles.each { |inf| cmd += " '#{inf}'" }
    $stderr.puts "%#{PROGNAME}-I-ECHO, $ #{cmd}" if options[:debug] > DBGLVL0
    $stdout.puts "%#{PROGNAME}-I-WORKING, be patient - oggCat converting (~Nsec/Mb)"
    %x{ #{cmd} }
    stat = $?.exitstatus
    if stat == 0
      delfiles( infiles, options ) if options[:remove]
    else
      $stderr.puts "%#{PROGNAME}-E-STAT, exit: #{stat}"
      $stderr.puts "-W-INSTALLED, is oggCat (oggvideotools) installed?" if stat == 127
      exit stat
    end  # if stat == 0
  when "mp3"
    if options[:debug] > DBGLVL0
      $stderr.puts "%#{PROGNAME}-I-CALL, copycat()..."
    else
      copycat( outfile, infiles, options )
      delfiles( infiles, options ) if options[:remove]
    end  # if options[:debug] > DBGLVL0
  else
    $stderr.puts "%#{PROGNAME}-E-BADFILE, unsupported file type #{options[:type]}"
    exit false
  end  # case options[:type]
  filez = "files"  # ...several
end  # if infcount == 1

# Summary...
$stderr.puts "%#{PROGNAME}-I-CONCATENATED, #{infcount} #{filez} >> \"#{File.basename outfile}\"" if options[:verbose]
exit true
