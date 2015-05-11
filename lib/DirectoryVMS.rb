#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# DirectoryVMS.rb
#
# Copyright © 2011-2015 Lorin Ricker <Lorin@RickerNet.us>
# Version 6.1, 05/11/2015
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
    @options   = options
    @dircolor  = :blue
    # 24-chars total date/time-field:
    @datetimeformat = "%a %d-%b-%Y %H:%M:%S"
    # Initialize per-subdir and grand nfiles/total:
    @numberfiles      = 0
    @totalsize        = 0
    @grandtotalnfiles = 0
    @grandtotalsize   = 0
  end  # initialize

  # ------------------------------------------
  def canonical_path( cp, p )
    cpath = File.absolute_path( p, cp )
    cpath = File.dirname( cpath ) if !File.directory?( cpath )
    cpath = cpath + "/" if cpath[-1] != "/"
    return [ cpath, File.basename( p ) ]
  end  # canonical_path

  def printheader( dir )
    printf( "\nDirectory %s\n\n", dir.bold.underline.color(@dircolor) )
  end  # printheader

  def printentry( fname, is_dir, fsize, mtime, prot )
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
    if is_dir  # embellish directories
      fname  = fname + '/'
      format = "%-#{fnwidth}s".color(@dircolor).bold +
               "  %#{szwidth}s  %#{dtwidth}s  %#{prwidth}s\n"
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

  def reportentry( fspec )
    # Use File.lstat (not File.stat), so actual links are processed too:
    fstat  = File.lstat( fspec )
    # Recognize the subdirectories as encountered:
    is_dir = fstat.directory? && fspec[-1] != "/"
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
    # Get the file's ownership "user:group (uid:gid)" ...stash in the hash:
    @options[:fowner] = File.owner_human_readable( fstat ) if @options[:owner]
    # Print the entry for this file:
    printentry( File.basename( fspec ), is_dir, fsize, mtime, prot )
    @numberfiles += 1
    @grandtotalnfiles += 1
  end  # reportentry

  def printtrailer( nfiles, tsize, grand = "" )
    newline = ( nfiles == 0 && tsize == 0 ) ? "" : "\n"
    files   = nfiles == 1 ? "file" : "files"
    bytes   =  tsize == 1 ? "byte" : "bytes"
    tsize   = @options[:bytesize] ?
              tsize.to_s.thousands : File.size_human_readable( tsize )
    printf( "%s%sTotal of %d %s, %s %s\n", newline, grand, nfiles, files, tsize, bytes )
    @numberfiles = 0
    @totalsize   = 0
  end  # printtrailer

  def printgrand
    printtrailer( @grandtotalnfiles, @grandtotalsize, "Grand " )
  end  # printgrand

  # ------------------------------------------
  def filterAfter( fspecs, fdate )
    nspecs = []
    fspecs.each do |f|
      nspecs << f if File.lstat(f).mtime >= fdate
    end
    nspecs
  end  # filterAfter

  def filterBefore( fspecs, fdate )
    nspecs = []
    fspecs.each do |f|
      nspecs << f if File.lstat(f).mtime <= fdate
    end
    nspecs
  end  # filterBefore

  def filterLarger( fspecs, fsize )
    nspecs = []
    fspecs.each do |f|
      nspecs << f if File.lstat(f).size >= fsize
    end
    nspecs
  end  # filterLarger

  def filterSmaller( fspecs, fsize )
    nspecs = []
    fspecs.each do |f|
      nspecs << f if File.lstat(f).size <= fsize
    end
    nspecs
  end  # filterSmaller

  # ------------------------------------------
  def listing( args, recursing = nil )
    code = Diagnostics::Code.new( colorize = 'red' )
    @numberfiles = @totalsize = 0

    arg = args.pop    # start with the last-most argument
    dirstack = args   # ...save the rest for later (recurse)
    arg = "*" if arg == ""
    # Will Dir.glob generate recursive descent (all files)?
    argrecurses = arg.index( '**' ) || recursing
    # If so, replace globbing '**' and allow recursing to do its job...
    arg = arg.gsub( /[\*]{2,}/, '' ).gsub( /[\/]{2,}/, '/' )
    arg = File.join( arg, '*' ) if File.directory?( arg )

    curdir ||= ""
    curdir, arg = canonical_path( curdir, arg )
    if @options[:debug] >= DBGLVL2
      puts "\ncd --> #{curdir}".color(:blue)
      puts "argrecurses: '#{argrecurses}'".color(:blue)
      puts "arg: '#{arg}'"
    end

    direntries = Dir.glob( File.join( curdir, arg ), File::FNM_DOTMATCH )
    # Remove the back- and self- directory links
    direntries.delete_if { | e | File.basename( e ) == '.' ||
                                 File.basename( e ) == '..'}

    # Filter for user-specified dates &/or sizes...
    # direntries is same or smaller after each filter:
    direntries = filterAfter(   direntries, @options[:after]   ) if @options[:after]
    direntries = filterBefore(  direntries, @options[:before]  ) if @options[:before]
    direntries = filterLarger(  direntries, @options[:larger]  ) if @options[:larger]
    direntries = filterSmaller( direntries, @options[:smaller] ) if @options[:smaller]
    direntries.sort_caseblind!( @options[:reverse] )

    code.diagnose( direntries, "in listing (top)", __LINE__ ) if @options[:debug] >= DBGLVL2

    td = ""
    if ! direntries.empty?
      direntries.each do | fspec |
        if td != curdir
          printheader( curdir )
          td = curdir
        end
        # code.trace( fspec: fspec, dir: "#{curdir} - '#{td}'", dirstack: dirstack ) if @options[:debug] >= DBGLVL2
        if File.directory?( fspec ) && ( argrecurses || @options[:recurse] )
          # Push subdir onto the to-do (recursion) stack:
          dirstack << fspec
        end
        reportentry( fspec )
      end  # direntries.each
      printtrailer( @numberfiles, @totalsize )
      exit true if !askprompted( '>>> Continue', 'No' ) if @options[:debug] >= DBGLVL3
    else
      printheader( curdir )
      printtrailer( 0, 0 )  # ...for an empty directory
    end  # if !direntries.empty?

    # Recurse: Each subdirectory is listed after all files...
    if ! dirstack.empty?
      code.diagnose( dirstack, "in listing (recursing)", __LINE__ ) if @options[:debug] >= DBGLVL2
      dirstack.each { | nextdir | listing( [ nextdir ], argrecurses ) }
    end

  end  # listing

end  # class DirectoryVMS
