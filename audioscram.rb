#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# audioscram.rb ("Audio Scramble")
#
# Copyright © 2014 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# ===========
#  Problem: I own and use a SanDisk "Sansa" MP3 Media Player, a little
#           tiny thing which currently is loaded with over 40Gb of memory,
#           which amounts to *a lot* of music.
#
#           I've noticed that, whenever I load new MP3 files to it, it goes
#           through a "refreshing playlist" operation, which seems to result
#           in a playlist order from most-recently loaded to old(er).  This
#           means that I hear the most recently loaded music first (if I
#           select "All Music" to play from "the beginning").
#
#           I have an great memory for not only the music itself, but also
#           for the order in which it's played.  Hence, if I start hearing
#           the same works played in the same order, "That ain't right..."
#           occurs to me immediately.  I hate listening to the same old
#           program cycle over and over again.  But how to mix it up?
#
# Solution: * I need to be able to occasionally reload the Player "from scratch"
#           * and in a randomized load-order, so that it will build a new and
#           * different internal playlist with each reload.

# Specifics --
#  RipLibrary - My entire (growing) library of ripped music is stored/mirrored
#               on-disk (system/node music) under a directory tree
#
#                 /usr/Mirrors/LorinLibrary/MusicLibrary/CDrips/RipLibrary/...
#
#               This dir-tree is further subdivided into genre and categories
#               of my own design/choosing.  At this writing (May'2014), this
#               RipLibrary/... contains over 1,020 music works (I detest the
#               vernacular "song" for a musical work -- a song is  particular
#               musical form, not a generic, imprecise term).  Multi-movement
#               works are catenated into a single .mp3 file using audiocat(.rb).
#               This count will only grow as I continue to rip CDs to .mp3, and
#               possibly .ogg (Ogg Vorbis), formats.
#
#      Memory - The sub-tree structure of ./RipLibrary/... is mirrored on the
#               Sansa Player (memory), and this appears to have no influence
#               on the Player's self-constructed playlist whenever it rebuilds.
#
#    Playlist - The Player rebuilds whenever I load/reload MP3 files to it;
#               the playlist works LIFO-like: latest-in, first-played.

# ===========
# Command Line --
#   $ audioscram [options] /media/player/path/ [ ./RipLibrary/path ]
#
#     /media/player/path/ is the first argument so that ./RipLibrary/path
#     can be defaulted to current working directory, as desired.

# Process/Algorithm --
#
# 1. General approach is to randomize the order in which works are copied to
#    the Player.  Given the same repertory of works in ./RipLibrary/..., each
#    successive re-load will present (copy) the works in a different, arbitrary
#    order.
#
# 2. Player's repertory may or may not be deleted (erased) before a re-load.
#    Only .mp3 and/or .ogg files will be removed, leaving any residual dir-tree
#    intact (full memory/device re-initialization or rm -rf would be done as a
#    manual operation outside the scope of this program).
#
# 3. Player's memory auto-mounts (under Linux) as one or two USB devices (just
#    like USB memory sticks).  This program presumes that the Player's devices
#    (memory) is mounted, ready to go.
#
# 4. After parsing command-line options (OptionParser), this program:
#
#    a) Counts all works (.mp3 files) currently in ./RipLibrary/...;
#       this Count is used to compute a range 1..UL, where UL (upper
#       limit) is Count * ScaleFactor, and ScaleFactor simply expands
#       the range of random numbers we'll use later, hopefully preventing
#       collisions among unique pairing assignments.
#
#    b) Based on com-line options, any Player file-removals (erasures)
#       are done.
#
#    c) Using Dir.glob on the ./RipLibrary/path, MP3 (or Ogg) files are
#       paired with a unique random number (integer) from the range 1..UL
#       (and any collisions are retried until a unique random number is
#       obtained).  This pair is tucked into a hash as Rand-Int => MP3-file.
#       Yes, this will become a large hash.
#
#    d) When all music files have been paired and tucked into the hash, the
#       hash is sorted, resulting in a (large) sorted array of array-pairs.
#
#    e) Filenames are extracted in sort-order from this array and re-copied
#       to the Player -- Files are copied back to the relatively same sub-
#       directory as their source location; if that sub-directory does not
#       yet exist on the Player, it is created before the copy.
#
#    f) When all filenames are extracted from the array and all files are
#       copied to the player, the result is a newly randomized load order.
#       When the Player next rebuilds its internal playlist, that playlist
#       will exhibit a new, random-play order as desired.


PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.00 (06/02/2014)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

   CONFIGDIR = File.join( ENV['HOME'], ".config", "#{PROGNAME}" )
  CONFIGFILE = File.join( "#{CONFIGDIR}", ".#{PROGNAME}.yaml.rc" )

# === For command-line arguments & options parsing: ===
require 'optparse'        # See "Pickaxe v1.9", p. 776
require 'pp'
require 'fileutils'
require 'yaml'
require_relative 'ANSIseq'
require_relative 'FileEnhancements'

# ==========

options = {  # hash for all com-line options:
  :keep    => false,
  :help    => false,
  :about   => false,
  :dryrun  => false,
  :debug   => false,
  :verbose => false
  }

optparse = OptionParser.new { |opts|
  # --- Program-Specific options ---
  opts.on( "-k", "--keep", "keep (do not erase) existing player repertory" ) do |val|
    options[:keep] = true
  end  # -k --keep
  opts.on( "-r", "--refresh", "refresh each player repertory file" ) do |val|
    options[:refresh] = true
  end  # -r --refresh
  # --- Set the banner & Help option ---
  opts.banner = "Usage: #{PROGNAME} [options] /media/player/path ./RipLibrary/path"
  opts.on( "-?", "-h", "--help", "Display this help text" ) do |val|
    puts opts
    exit true
  end  # -? --help
  # --- About option ---
  opts.on( "-a", "--about", "Display program info" ) do |val|
    puts "#{PROGID}"
    puts "#{AUTHOR}"
    exit true
  end  # -a --about
  # --- DryRun option ---
  opts.on( "-n", "--dryrun", "Dry run: do not actually modify files or environment" ) do |val|
    options[:dryrun] = true
  end  # -n --dryrun
  # --- Debug option ---
  opts.on( "-d", "--debug", "Debug mode (more output than verbose)" ) do |val|
    options[:debug] = true
  end  # -d --debug
  # --- Verbose option ---
  opts.on( "-v", "--verbose", "Verbose mode" ) do |val|
    options[:verbose] = true
  end  # -v --verbose
}.parse!  # leave residue-args in ARGV

# Some options override:
options[:keep] = true if options[:refresh]

# Configure FileUtils options from audioscram com-line options:
fopts = Hash.new
fopts[:verbose] = options[:verbose] || options[:dryrun]
fopts[:noop]    = options[:dryrun]

# TO-DO
# Player mounts as /dev/sdb ("/media/lorin/SANSA CLIPP"), type vfat
#           and as /dev/sdc1 ("/media/lorin/4219-1B1E"), type vfat
#
# Reformat with new labels POPMUSIC and CLSMUSIC (still type vfat)
#
# Be sure that Player's Settings | System Settings | USB Mode
# is set to MCS (not MTP or Auto Detect)...
#

# Get player-path from 1st com-line arg, expand it if necessary:
player = File.dirname( ARGV[0] )
player = Dir.pwd if player == '.'
puts "player is '#{player}'" if options[:verbose]

# Get source-path from 2st com-line arg, expand it if necessary:
source = File.dirname( ARGV[1] )
source = Dir.pwd if source == '.'
puts "source is '#{source}'" if options[:verbose]

# Count music files in this source-path:
MFSCALE = 10000
mp3spec = File.join( source, "**", "*.mp3" )
cnt = Dir.glob( mp3spec ).count
uplim = cnt * MFSCALE
puts "Music file count: #{cnt}, upper limit: #{uplim}" if options[:verbose]

# Randomize -- pair each music file with a random number:
randgen = Random.new( Random.new_seed )
scramhash = Hash.new
maxcolcnt = 0
Dir.glob( mp3spec ).each do | mf |
  # Search for an unpaired random number (usually hits the first time):
  colcnt = 0
  until ! scramhash[ rno = randgen.rand( 1..uplim ) ]
    colcnt += 1  # Aha! A random key collision!...
  end
  scramhash[rno] = mf
  maxcolcnt = colcnt if maxcolcnt < colcnt   # Track maximum # of random hash key collisions
end  # Dir.glob
## pp scramhash if options[:verbose]
msg = "Maximum random hash key collisions: #{maxcolcnt}"
puts msg if options[:verbose] && maxcolcnt > 0

# Randomized -- sort the music files by random# -- a hash sort
#   produces a nested array: [[k1,v1],[k2,v2],[k3,v3]...]:
scramarry = scramhash.sort
scramarry.each { |e| puts "#{e[0]}: #{File.basename( e[1] )}" } if options[:verbose]

# TO-DO:
# (X) OptionParse
# ( ) if !options[:keep], remove files from /media/player/path/
# (X) SCALEFACTOR = 10000
# (X) cnt = Dir.glob( "./RipLibrary/**/*.mp3" ).count
# (X) uplim = cnt * SCALEFACTOR
# (X) randgen = Random.new( Random.new_seed )
# (X) scramhash = Hash.new
# (X) Dir.glob( "./RipLibrary/**/*.mp3" ).each do |f|
#      rno = randgen.rand( 1..uplim )
#      scramhash[rno] = mf
#      end
#
# (X) scramarry = scramhash.sort
# ( ) scramarry.each do |pair|
# ( )   if options[:refresh], copy MP3 (overwrite existing),
#       else copy MP3 only if it does not exist in Player
#       copy pair[1] to /media/player/path/: cp( "src"... "dst" )
#       end
