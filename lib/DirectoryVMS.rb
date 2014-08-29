#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# DirectoryVMS.rb
#
# Copyright © 2011-2014 Lorin Ricker <Lorin@RickerNet.us>
# Version 4.4, 08/28/2014
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
require_relative 'Diagnostics'

class DirectoryVMS

  def initialize( termwidth, options )
    @termwidth = termwidth
    @options = options
    # 24-chars total date/time-field:
    @datetimeformat = "%a %d-%b-%Y %H:%M:%S"
    # Initialize per-subdir and grand nfiles/total:
    @numberfiles = 0
    @totalsize   = 0
    @grandtotalnfiles = 0
    @grandtotalsize   = 0
    # And the current working directory:
    @curdir = ""
  end  # initialize

  # ------------------------------------------
  def canonical_path( p, cp = @curdir )
    cpath = File.absolute_path( p, cp )
    cpath = File.dirname( cpath ) if !File.directory?( cpath )
    cpath = cpath + "/" if cpath[-1] != "/"
    return cpath
  end  # canonical_path

  def printheader( dir )
    printf( "\nDirectory %s\n\n", dir.bold.underline )
  end  # printheader

  def printentry( fspec, fsize, mtime, prot )
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
    fnwidth  = @termwidth - sdpwidth if @termwidth < fnwidth + sdpwidth
    if fspec[-1] == "/"  # embellish directories
      format = "%-#{fnwidth}s".bold + "  %#{szwidth}s  %#{dtwidth}s  %#{prwidth}s\n"
    else
      format = "%-#{fnwidth}s  %#{szwidth}s  %#{dtwidth}s  %#{prwidth}s\n"
    end  # if fspec[-1]
    fspec = fspec[0,fnwidth-1] + '*' if fspec.length > fnwidth
    printf( format, fspec, size, mtime, prot )
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

  def reportentry( dir, fspec )
    # Use File.lstat (not File.stat), so actual links are processed too:
    fstat  = File.lstat( File.join( dir, fspec ) )
    # Collect the file's size in bytes, and accumulate total size
    fsize  = fstat.size
    @totalsize += fsize
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
    # Mark the subdirectories as encountered:
    fspec = fspec + "/" if fspec[-1] != "/" if fstat.directory?
    # Get the file's ownership "user:group (uid:gid)" ...stash in the hash:
    @options[:fowner] = File.owner_human_readable( fstat ) if @options[:owner]
    # Print the entry for this file:
    printentry( fspec, fsize, mtime, prot )
    @numberfiles += 1
    @grandtotalnfiles += 1
  end  # reportentry


  def printtrailer( nfiles, tsize, grand = "" )
    files = nfiles == 1 ? "file" : "files"
    bytes = tsize == 1 ? "byte" : "bytes"
    tsize = @options[:bytesize] ?
            tsize.to_s.thousands : File.size_human_readable( tsize )
    newline = ( nfiles == 0 && tsize == 0 ) ? "" : "\n"
    printf( "%s%sTotal of %d %s, %s %s\n", newline, grand, nfiles, files, tsize, bytes )
  end  # printtrailer

  def printgrand
    printtrailer( @grandtotalnfiles, @grandtotalsize, "Grand " )
  end  # printgrand

  # ------------------------------------------
  def filterBefore( fspecs, fdate )
    nspecs = []
    fspecs.each do |f|
      nspecs << f if File.directory?(f) || File.lstat(f).mtime <= fdate
    end
    nspecs
  end  # filterBefore

  def filterSince( fspecs, fdate )
    nspecs = []
    fspecs.each do |f|
      nspecs << f if File.directory?(f) || File.lstat(f).mtime >= fdate
    end
    nspecs
  end  # filterSince

  def filterLarger( fspecs, fsize )
    nspecs = []
    fspecs.each do |f|
      nspecs << f if File.directory?(f) || File.lstat(f).size >= fsize
    end
    nspecs
  end  # filterLarger

  def filterSmaller( fspecs, fsize )
    nspecs = []
    fspecs.each do |f|
      nspecs << f if File.directory?(f) || File.lstat(f).size <= fsize
    end
    nspecs
  end  # filterSmaller

  # ------------------------------------------
  def listing( args )
    code = Diagnostics::Code.new( colorize = 'red' )
    @numberfiles = @totalsize = 0

    dir = args.pop    # start with the last-most argument
    dirstack = args   # ...save the rest for later (recurse)
    dir = "." if dir == ""
    dir = canonical_path( dir, @curdir )
    puts "\ncd --> #{dir}\n  pwd: #{Dir.pwd}".color(:blue) if @options[:debug] >= DBGLVL1
    if Dir.pwd != File.basename( dir )
      Dir.chdir( dir )
      @curdir = dir
    end
    direntries = Dir.entries( dir )
    direntries.delete( "." )    # remove the back- and self-links
    direntries.delete( ".." )

    # Filter for user-specified dates &/or sizes...
    # direntries is same or smaller after each filter:
    direntries = filterBefore(  direntries, @options[:before]  ) if @options[:before]
    direntries = filterSince(   direntries, @options[:since]   ) if @options[:since]
    direntries = filterLarger(  direntries, @options[:larger]  ) if @options[:larger]
    direntries = filterSmaller( direntries, @options[:smaller] ) if @options[:smaller]
    direntries.sort_caseblind!( @options[:reverse] )

    code.diagnose( direntries, "in listing (top)", __LINE__ ) if @options[:debug] >= DBGLVL2

    printheader( dir )
    if !direntries.empty?
      direntries.each do | fspec |
        # Push subdir onto the to-do (recursion) stack:
        nd = File.absolute_path( fspec, @curdir )
        dirstack << nd if File.directory?( nd )
        code.trace( fspec: fspec, dirstack: dirstack, dir: dir ) if @options[:debug] >= DBGLVL3
        ## puts ">>> fspec: '#{fspec}'  fspec: '#{fspec}'\n dirstack: #{dirstack}  dir: '#{dir}'".color(:blue)  if @options[:debug] >= DBGLVL3
        reportentry( dir, fspec )
      end  # direntries.each
      printtrailer( @numberfiles, @totalsize )
      exit true if !askprompted( '>>> Continue', 'No' ) if @options[:debug] >= DBGLVL3
    else
      printtrailer( 0, 0 )  # ...for an empty directory
    end  # if !direntries.empty?

    # Recurse: Each subdirectory is listed after all files...
    if @options[:recurse] && !dirstack.empty?
      code.diagnose( dirstack, "in listing (recursing)", __LINE__ ) if @options[:debug] >= DBGLVL2
      dirstack.each { | nextdir | listing( [ nextdir ] ) }
    else
      printgrand if @options[:grand]
    end

  end  # listing

end  # class DirectoryVMS
