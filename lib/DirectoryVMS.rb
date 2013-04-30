#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# DirectoryVMS.rb
#
# Copyright © 2011-2012 Lorin Ricker <Lorin@RickerNet.us>
# Version 3.3, 10/23/2012
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

require 'pp'

require_relative 'FileEnhancements'  # relies on RUBYLIB env-var
require_relative 'StringEnhancements'
require_relative 'ANSIseq'

class DirectoryVMS

  # 24-chars total date/time-field:
  @@dtformat = "%a %d-%b-%Y %H:%M:%S"

  # Initialize grand nfiles/total:
  @@gnfiles  = 0
  @@gtsize   = 0

  def self.finishdir( d )
    dir = File.expand_path( d )
    dir = dir + "/" if dir[-1] != "/"
    return dir
  end  # finishdir

  def self.printheader( dir )
    printf( "\nDirectory %s\n\n", dir.bold.underline )
  end  # printheader

  def self.printentry( termwidth, fname, fsize, mtime, prot, options )
    if options[:bytesize]
      size = fsize.to_s
      szwidth = 9
    else
      size = File.size_human_readable( fsize )
      szwidth  = 6
    end  # if options[:bytesize]
    dtwidth  = mtime.size
    prwidth  = prot.size
     owidth  = 20
    sdpwidth = szwidth + dtwidth + prwidth + 6  # 6 = "  "*3 between fields
    fnwidth  = termwidth / 2
    fnwidth  = termwidth - sdpwidth if termwidth < fnwidth + sdpwidth
    if fname[-1] == "/"  # embellish directories
      format = "%-#{fnwidth}s".bold + "  %#{szwidth}s  %#{dtwidth}s  %#{prwidth}s\n"
    else
      format = "%-#{fnwidth}s  %#{szwidth}s  %#{dtwidth}s  %#{prwidth}s\n"
    end  # if fname[-1]
    fname = fname[0,fnwidth-1] + '*' if fname.length > fnwidth
    printf( format, fname, size, mtime, prot )
    if options[:times]
      inwidth = fnwidth + szwidth + 4
      format = "%#{inwidth}s%#{dtwidth}s\n%#{inwidth}s%#{dtwidth}s\n"
      printf( format, "a:", options[:atime], "c:", options[:ctime] )
    end  # if options[:times]
    if options[:owner]
      owidth += fnwidth + szwidth + 11
      format = "%#{owidth}s\n"
      printf( format, options[:fowner] )
    end  # if options[:times]
  end  # printentry

  def self.printtrailer( nfiles, tsize, options, grand = "" )
    files = nfiles == 1 ? "file" : "files"
    bytes = tsize == 1 ? "byte" : "bytes"
    tsize = options[:bytesize] ?
            tsize.to_s.thousands : File.size_human_readable( tsize )
    printf( "\n%sTotal of %d %s, %s %s\n", grand, nfiles, files, tsize, bytes )
  end  # printtrailer

  def self.printgrand( options )
    printtrailer( @@gnfiles, @@gtsize, options, "Grand " )
  end  # printgrand

  def self.filterBefore( fspecs, fdate )
    nspecs = []
    fspecs.each do |f|
      nspecs << f if File.directory?(f) || File.lstat(f).mtime <= fdate
    end
    nspecs
  end  # filterBefore

  def self.filterSince( fspecs, fdate )
    nspecs = []
    fspecs.each do |f|
      nspecs << f if File.directory?(f) || File.lstat(f).mtime >= fdate
    end
    nspecs
  end  # filterSince

  def self.filterLarger( fspecs, fsize )
    nspecs = []
    fspecs.each do |f|
      nspecs << f if File.directory?(f) || File.lstat(f).size >= fsize
    end
    nspecs
  end  # filterLarger

  def self.filterSmaller( fspecs, fsize )
    nspecs = []
    fspecs.each do |f|
      nspecs << f if File.directory?(f) || File.lstat(f).size <= fsize
    end
    nspecs
  end  # filterSmaller

  def self.listing( args, termwidth, recurse, options )
    # Remember transitions between distinct directories:
    @@curDir = ""
    # Establish scope of nfiles & tsize as "global" to enum-blocks below:
    nfiles = tsize = 0

    directories ||= []

    args.each do | fspec |
      # Arguments containing trailing "..." (e.g., dir... or literal ...)
      # mean to recurse (display subdirectories of the directory).
      # Default is for the current directory only:
      fspec = "." if fspec == ""
      # recurse ||= options[:recurse]
      if fspec[-3,3] == "..." || options[:recurse]
        recurse = true
        fspec = fspec == "..." ? "." : fspec[0..(fspec.size-4)]
      end  # if fspec[-3,3]
      if File.directory?( fspec )
        fname = ""
        dir   = fspec
      else
        fname = File.basename( fspec )
        dir   = File.dirname( fspec )
      end  # if File.directory?
      dir = finishdir( dir )
      # puts "  dir: '#{dir}'\nfname: '#{fname}'" if options[:verbose]

      Dir.chdir( dir ) do | path |
        if dir != @@curDir
          printtrailer( nfiles, tsize, options ) if @@curDir != ""
          nfiles = tsize = 0  # reset
          printheader( dir )
          @@curDir = dir
        end

        # Collect full file-specs of all files in this directory,
        # or full file-spec of this particular file:
        fspecs = fname == "" ? Dir.entries( dir ) : Dir[ fname ]

        # Filter for user-specified dates &/or sizes...
        # fspecs is smaller (or same) after each filter:
        fspecs = filterBefore(  fspecs, options[:before]  ) if options[:before]
        fspecs = filterSince(   fspecs, options[:since]   ) if options[:since]
        fspecs = filterLarger(  fspecs, options[:larger]  ) if options[:larger]
        fspecs = filterSmaller( fspecs, options[:smaller] ) if options[:smaller]

        # We want a case-blind sort: all "a..." with all "A...", etc.
        fspecs.sort! { |a,b| a.downcase <=> b.downcase }
        fspecs.reverse! if options[:reverse]

        fspecs.each do |f|
          next if f == '.' or f == '..'  # skip directory back- and self-links
          # Use File.lstat (not File.stat), so actual links are processed:
          fstat  = File.lstat( f )
          # Collect the file's size in bytes, and accumulate total size
          fsize     = fstat.size
          tsize    += fsize
          @@gtsize += fsize
          # Get the file's modification date/time, and optionally
          # the last-access and creation date/times
          mtime  = fstat.mtime.strftime( @@dtformat )
          if options[:times]
            # ...stash in the hash:
            options[:atime] = fstat.atime.strftime( @@dtformat )
            options[:ctime] = fstat.ctime.strftime( @@dtformat )
          end  # if options[:times]
          # Get the file's protection mask (mode) as human-readable (not integer)
          prot = File.mode_human_readable_VMS( fstat )
          # Collect subdirectories for recursive display
          if fstat.directory?
            d = finishdir( f )
            f = f + "/" if f[-1] != "/"
            directories << d
          end  # if fstat.directory?
          nfiles    += 1
          @@gnfiles += 1
          # Get the file's ownership "user:group (uid:gid)" ...stash in the hash:
          options[:fowner] = File.owner_human_readable( fstat ) if options[:owner]

          # Print the entry for this file
          printentry( termwidth, f, fsize, mtime, prot, options )
        end  # fspecs.each

        puts "recurse: '#{recurse}'   directories: #{directories}" if options[:verbose]

        # Honor any detected "..." recursive listing:
        listing( directories, termwidth, recurse, options ) if recurse

      end  # Dir.chdir( dir )...
    end  # ARGV.each

    # Now, any finish-up output:
    printtrailer( nfiles, tsize, options )
    DirectoryVMS.printgrand( options ) if options[:grand]
    return true
  end  # listing

end  # class DirectoryVMS
