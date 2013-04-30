#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# audiocat.rb
#
# Copyright © 2012-2013 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.03 (02/24/2013)"
  AUTHOR = "Lorin Ricker, Franktown, Colorado, USA"

   CONFIGDIR = File.join( ENV['HOME'], ".config", "#{PROGNAME}" )
  CONFIGFILE = File.join( "#{CONFIGDIR}", ".#{PROGNAME}.yaml.rc" )
MUSICIANFILE = File.join( "#{CONFIGDIR}", ".#{PROGNAME}.yaml.musicians" )

# === For command-line arguments & options parsing: ===
require 'optparse'        # See "Pickaxe v1.9", p. 776
require 'pp'
require 'fileutils'
require 'yaml'
require_relative 'ANSIseq'
require_relative 'FileEnhancements'

# ==========

def checkdir( confdir, perms = 0700 )
  Dir.mkdir( confdir, perms ) if ! Dir.exists?( confdir )
end  # checkdir

def configuration( cfile, config, saveoverride = false )
  if File.exists?( cfile ) && ! saveoverride
    lconfig = YAML.load_file( cfile )
    options.merge!( lconfig )
  else
    File.open( cfile, 'w' ) { |f| YAML::dump( config, f ) }
    $stderr.puts "%#{PROGNAME}-I-init, config-file #{cfile} initialized"
  end  # if File.exists? cfile
end  # configuration

def copycat( infiles, outfile, options )
  # Copy-catenate infiles to outfile
  ifl, inf = "", ""
  ofl = File.basename outfile
  begin
    File.open( outfile, mode: "ab" ) do | outf |
      infiles.each_with_index do | infile, idx |
        ifl = File.basename infile
        $stderr.puts "%#{PROGNAME}-I-COPYCAT, '#{ifl}' >> '#{ofl}'" if options[:verbose]
        # Inhale and exhale the whole thing...
        unless options[:dryrun]
          inf = File.open( infile, mode: "rb" )
          IO.copy_stream( inf, outf )
          inf.close
        end  # unless options[:dryrun]
        unless options[:keep]
          # Clean-up... remove (with permission) all of the infiles
          $stderr.puts "%#{PROGNAME}-I-RM, delete #{ifl}" if options[:verbose]
          FileUtils.rm [ infile ] unless options[:dryrun]
        end  # unless options[:keep]
      end  # infiles.each_with_index
    end  # IO.open( outfile, ... )
  rescue Exception => e
    $stderr.puts "%#{PROGNAME}-E-COPYCAT, error in copy or delete: '#{ifl}'"
    pp e
    print e.backtrace.join( "\n" )     # Catch-all, display the unexpected...
  end
end  # copycat

# ==========

composers = {  # Just a starter set -- edit the .yaml file for future updates:
  "Alka"  => "Charles Valentin Alkan",
  "JSB"   => "Johann Sebastian Bach",
  "LvB"   => "Ludwig von Beethoven",
  "JBr"   => "Johannes Brahms",
  "BB"    => "Bela Bartók",
  "Buso"  => "Ferruccio Busoni",
  "Cart"  => "Elliot Carter",
  "Copl"  => "Aaron Copland",
  "Fein"  => "Samuil Feinberg",
  "Gers"  => "George Gershwin",
  "Godo"  => "Leopold Godowsky",
  "Grai"  => "Percy Grainger",
  "Hind"  => "Paul Hindemith",
  "Ives"  => "Charles Ives",
  "Kapu"  => "Nikolai Kapustin",
  "Lisz"  => "Franz Liszt",
  "Mart"  => "Bohuslav Martinů",
  "Medt"  => "Nikolai Medtner",
  "Mend"  => "Felix Mendelssohn",
  "Nanc"  => "Conlon Nancarrow",
  "Orns"  => "Leo Ornstein",
  "Pers"  => "Vincent Persichetti",
  "Prok"  => "Sergei Prokofiev",
  "Rach"  => "Sergei Rachmaninov",
  "Rzew"  => "Frederic Rzewski",
  "Shos"  => "Dmitri Shostakovich",
  "Sora"  => "Kaikhosru Shapurji Sorabji",
  "Stra"  => "Igor Stravinsky",
  "Stev"  => "Ronald Stevenson",
  "Vill"  => "Heitor Villa-Lobos",
  "Vine"  => "Carl Vine"
  }

pianists = {
  "Mart"  => "Martha Argerich",
  "Malc"  => "Malcolm Bilson",
  "Dave"  => "Dave Brubeck",
  "Gerg"  => "Georges Cziffra",
  "Erro"  => "Errol Garner",
  "Rich"  => "Richard Goode",
  "Glen"  => "Glenn Gould",
  "Vlad"  => "Vladimir Horowitz",
  "Marc"  => "Marc-André Hamelin",
  "Step"  => "Stephen Hough",
  "Olga"  => "Olga Kern",
  "John"  => "John Ogdon",
  "Osca"  => "Oscar Peterson",
  "Andr"  => "Andre Previn",
  "Svia"  => "Sviatoslav Richter",
  "Char"  => "Charles Rosen",
  "Howa"  => "Howard Shelley"
  }

options = {  # hash for all com-line options:
  :help   => false,
  :about  => false,
  :type   => "ogg",    # Set specific flags for YAML...
  :save   => false,
  :dryrun => false,
  :keep   => false,
  :debug  => false
  }

optparse = OptionParser.new do |opts|
  # Set the banner:
  opts.banner = "Usage: #{PROGNAME} [options] input_audio_file(s) output-audio-file"
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
  opts.on( "-t", "--type", "=[AUDIO]", /ogg|mp3|wav/i,
           "Audio-type of files (ogg (d), mp3, wav)" ) do |val|
    options[:type] = val || "ogg"
  end  # -t --type
  opts.on( "-s", "--save", "Save command-line configuration preferences" ) do |val|
    options[:save] = true
  end  # -s --save
  opts.on( "-n", "--dryrun", "Dry run: don't actually copy or delete files" ) do |val|
    options[:dryrun] = true
  end  # -n --dryrun
  opts.on( "-k", "--keep", "Keep (don't delete) input files" ) do |val|
    options[:keep] = true
  end  # -k --keep
  opts.on( "-v", "--verbose", "Verbose mode" ) do |val|
    options[:verbose] = true
  end  # -v --debug
  opts.on( "-d", "--debug", "Debug mode (more output than verbose)" ) do |val|
    options[:debug] = true
  end  # -d --debug
end  #OptionParser.new
optparse.parse!  # leave residue-args in ARGV

checkdir( CONFIGDIR )
configuration( MUSICIANFILE, composers )
save = options[:save]
options[:save] = false  # don't ever write true for this flag!...
configuration( CONFIGFILE, options, save )

# Propagate a couple of implications --
# (which should *not* be saved in the CONFIGFILE):
options[:keep]    ||= options[:dryrun]  # dryrun implies keep...
options[:debug]   ||= options[:dryrun]  # ...and also debug...
options[:verbose] ||= options[:debug]   # ...and debug implies verbose

puts "%#{PROGNAME}-I-FTYPE, audio filetype is '#{options[:type]}'" if options[:debug]

# ===========
# Reference & research -- install these packages:
#   vorbis-tools, ruby-ogginfo, tagtool
#   $ hexdump -Cn 1024 ogg-file
#
# See also these Ogg Vorbis tools:
#   ogginfo       -- parses Ogg Vorbis files with extensive validity checking
#   vorbiscomment -- List & edit Ogg Vorbis comments (single file)
#   vorbistagedit -- batch editing of Ogg Vorbis comments with an editor (nano)
#   tagtool       -- (GUI) editing of Ogg Vorbis comments (single/multi-files)

# Working with this file-type (extension):
fext = ".#{options[:type]}"

# Output file is the _last_ filespec in the ARGV list, pop it after assignment:
outfile = File.expand_path( File.default_extension( ARGV.pop, fext ) )

# Expand shorthands like two- "1..5" and three-dot "1...5"
# (either syntax allowed) into multiple files, e.g.:
#   "Track1..5"     --> "Track1", "Track2", "Track3", "Track4", "Track5"
#   "Track 12...14" --> "Track 12", "Track 13", "Track 14",... "Track 17"
infiles = []
pat = Regexp.new( /(^.*?)    # any prefix (lazy) m[1]
                  ([0-9]+)   # 1 or more digits  m[2]
                  (\.{2,3})  # ".." or "..."     m[3]
                  ([0-9]+)   # 1 or more digits  m[4]
                  (.*)       # any suffix        m[5]
                  /x )       # ..."Lazy" prefix gives _all_ of the first
                             #    digits to the first integer value

ARGV.each do | f |    # Each remaining file in ARGV is an input filespec...
  $stderr.puts "%#{PROGNAME}-I-ARGV, arg '#{f}'" if options[:debug]
  m = pat.match( f )
  if m
    # Logic to build file-range here...
    rng = m[2].to_i..m[4].to_i
    rng.each do | idx |
      inf = m[1] + idx.to_s + m[5]
      infiles << File.default_extension( File.expand_path( inf ), fext )
    end  # rng.each
    pp infiles if options[:debug]
  else
    infiles << File.default_extension( File.expand_path( f ), fext )
  end  # if m
end  # ARGV.each

fnflag = badflag = false
infiles.each do | inf |   # Validate each input file...
  if File.exists?( inf )
    $stderr.puts "%#{PROGNAME}-I-INFILE, input '#{inf}'" if options[:debug]
    if ! File.verify_magicnumber( inf )
      $stderr.puts "%#{PROGNAME}-E-BADMAGIC, wrong file signature: #{ inf }"
      badflag = true
    end  # if ! File.verify_magicnumber( inf )
  else
    $stderr.puts "%#{PROGNAME}-E-FNF, file not found: #{inf}"
    fnflag = true
  end  # if File.exists?( inf )
end  # infiles.each
exit true if fnflag || badflag

$stderr.puts "%#{PROGNAME}-I-OUTFILE, output '#{outfile}'" if options[:debug]

# (Can .ogg and .wav files also be concatenate-copied?  ogg -> Yes!)

# Copy-concatenate all infiles to the single outfile, & conditionally delete infiles
copycat( infiles, outfile, options )
