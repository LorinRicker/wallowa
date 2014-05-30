#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# audioscram.rb
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
#           But I have an excellent memory for not only the music itself, but
#           also for the order in which it's played.  Hence, if I start hearing
#           the same works played in the same order, "That ain't right..."
#           occurs to me immediately.
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
#   $ audioscram [options] player-device-subtree [ source-subtree ]
#
#     player-device-subtree is the first argument so that source-subtree can
#     be defaulted to current working directory, as desired.

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
#    c) Using Dir.glob on the source-subtree, MP3 (or Ogg) files are paired
#       with a unique random number (integer) from the range 1..UL (and any
#       collisions are retried until a unique random number is obtained).
#       This pair is tucked into a hash as Uni-Rand-Int -> MP3-file.  Yes,
#       this will become a large hash.
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
  PROGID = "#{PROGNAME} v1.00 (05/29/2014)"
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


# OptionParse
# remove files from player-device-subtree
# SCALEFACTOR = 10000
# fcnt = Dir.glob( "./RipLibrary/**/*.mp3" ).count
# UL = fcnt * SCALEFACTOR
# randy = Random.new( Random.new_seed )
# rno = randy.rand( 1..UL )
# fileshash = Hash.new
# Dir.glob( "./RipLibrary/**/*.mp3" ).each do |f|
#   rno = randy.rand( 1..UL )
#   fileshash << rno => f
#   end
#
# filesarray = fileshash.sort
# filesarray.each do |pair|
#   copy pair[1] to player-device-subtree
#   end

