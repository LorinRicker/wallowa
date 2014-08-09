#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# DirectoryVMS.rb
#
# Copyright © 2011-2014 Lorin Ricker <Lorin@RickerNet.us>
# Version 4.1, 08/08/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

require 'pp'

require_relative 'ArrayEnhancements'
require_relative 'FileEnhancements'
require_relative 'StringEnhancements'
require_relative 'ANSIseq'
require_relative 'AskPrompted'

class DirectoryVMS

  def initialize( termwidth, options )
    @termwidth = termwidth
    @options = options
    # Collect each directory for recursive-descent listing:
    @dirs = []
    # 24-chars total date/time-field:
    @datetimeformat = "%a %d-%b-%Y %H:%M:%S"
    # Initialize grand nfiles/total:
    @grandtotalnfiles = 0
    @grandtotalsize   = 0
  end  # initialize

  # ------------------------------------------
  def self.finishdir( d )
    dir = File.expand_path( d )
    dir = dir + "/" if dir[-1] != "/"
    return dir
  end  # finishdir

  def self.printheader( dir )
    printf( "\nDirectory %s\n\n", dir.bold.underline )
  end  # printheader

  def self.printentry( fname, fsize, mtime, prot )
    if @options[:bytesize]
      size = fsize.to_s
      szwidth = 9
    else
      size = File.size_human_readable( fsize )
      szwidth  = 6
    end  # if @options[:bytesize]
    dtwidth  = mtime.size
    prwidth  = prot.size
     owidth  = 20
    sdpwidth = szwidth + dtwidth + prwidth + 6  # 6 = "  "*3 between fields
    fnwidth  = @termwidth / 2
    fnwidth  = @termwidth - sdpwidth if termwidth < fnwidth + sdpwidth
    if fname[-1] == "/"  # embellish directories
      format = "%-#{fnwidth}s".bold + "  %#{szwidth}s  %#{dtwidth}s  %#{prwidth}s\n"
    else
      format = "%-#{fnwidth}s  %#{szwidth}s  %#{dtwidth}s  %#{prwidth}s\n"
    end  # if fname[-1]
    fname = fname[0,fnwidth-1] + '*' if fname.length > fnwidth
    printf( format, fname, size, mtime, prot )
    if @options[:times]
      inwidth = fnwidth + szwidth + 4
      format = "%#{inwidth}s%#{dtwidth}s\n%#{inwidth}s%#{dtwidth}s\n"
      printf( format, "a:", @options[:atime], "c:", @options[:ctime] )
    end  # if @options[:times]
    if @options[:owner]
      owidth += fnwidth + szwidth + 11
      format = "%#{owidth}s\n"
      printf( format, @options[:fowner] )
    end  # if @options[:times]
  end  # printentry

  def self.printtrailer( nfiles, tsize, grand = "" )
    files = nfiles == 1 ? "file" : "files"
    bytes = tsize == 1 ? "byte" : "bytes"
    tsize = @options[:bytesize] ?
            tsize.to_s.thousands : File.size_human_readable( tsize )
    printf( "\n%sTotal of %d %s, %s %s\n", grand, nfiles, files, tsize, bytes )
  end  # printtrailer

  def self.printgrand
    printtrailer( @grandtotalnfiles, @grandtotalsize, "Grand " )
  end  # printgrand

  # ------------------------------------------
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

  # ------------------------------------------
  def self.listing( args )
    # Remember transitions between distinct directories:
    curDir = ''
    # Establish scope of nfiles & tsize as "global" to enum-blocks below:
    nfiles = tsize = 0

    # Filter for user-specified dates &/or sizes...
    # args is smaller (or same) after each filter:
    args = filterBefore(  args, @options[:before]  ) if @options[:before]
    args = filterSince(   args, @options[:since]   ) if @options[:since]
    args = filterLarger(  args, @options[:larger]  ) if @options[:larger]
    args = filterSmaller( args, @options[:smaller] ) if @options[:smaller]

    args.sort_caseblind!( @options[:reverse] )

    Diagnostics.diagnose( args, "in listing (top)", __LINE__ ) if @options[:debug]

    args.each do | fspec |
      # Default is for the current directory only:
      fspec = "." if fspec == ""

      if File.directory?( fspec )
        fname  = ""
        dir    = fspec
        @dirs << fspec
        #next  # args.each
      else
        fname = File.basename( fspec )
        dir   = File.dirname( fspec )
      end  # if File.directory?
      dir = finishdir( dir )

      next if fspec == '.' or fspec == '..'  # skip directory back- and self-links
      puts ">>> fspec: '#{fspec}'  dirs: #{@dirs}"  if @options[:debug]
      puts "      dir: '#{dir}'  fname: '#{fname}'" if @options[:debug]

      if dir != curDir
        printtrailer( nfiles, tsize, @options ) if curDir != ""
        nfiles = tsize = 0  # reset
        printheader( dir )
        curDir = dir
      end

      # Use File.lstat (not File.stat), so actual links are processed too:
      fstat  = File.lstat( fspec )
      # Collect the file's size in bytes, and accumulate total size
      fsize  = fstat.size
      tsize += fsize
      @grandtotalsize += fsize
      # Get the file's modification date/time, and optionally
      # the last-access and creation date/times
      mtime  = fstat.mtime.strftime( @datetimeformat )
      if @options[:times]
        # ...stash in the hash:
        @options[:atime] = fstat.atime.strftime( @datetimeformat )
        @options[:ctime] = fstat.ctime.strftime( @datetimeformat )
      end  # if @options[:times]
      # Get the file's protection mask (mode) as human-readable (not integer)
      prot = File.mode_human_readable_VMS( fstat )
      # Collect subdirectories for recursive display
      if fstat.directory?
        d = finishdir( fspec )
        fspec = fspec + "/" if fspec[-1] != "/"
      end  # if fstat.directory?
      nfiles += 1
      @grandtotalnfiles += 1
      # Get the file's ownership "user:group (uid:gid)" ...stash in the hash:
      @options[:fowner] = File.owner_human_readable( fstat ) if @options[:owner]

      # Print the entry for this file:
      printentry( fspec, fsize, mtime, prot )

    end  # args.each

    # Finish-up the per-directory output:
    printtrailer( nfiles, tsize )
    exit true if !askprompted( '>>> Continue', 'No' ) if @options[:debug]

    # Recurse: Each subdirectory is listed after all files...
    # dgflags = File::FNM_CASEFOLD
    # dgflags = dgflags | File::FNM_DOTMATCH if @options[:hidden]
    if !@dirs.empty?
      Diagnostics.diagnose( args, "in listing (recursing)", __LINE__ ) if @options[:debug]
      @dirs.each do | d |
        dir = Dir.entries( d )
        listing( dir, termwidth )
      end
    end

    printgrand if @options[:grand]
    return true
  end  # listing

end  # class DirectoryVMS
