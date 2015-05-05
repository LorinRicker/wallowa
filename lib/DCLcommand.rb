#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# DCLcommand.rb
#
# Copyright © 2015 Lorin Ricker <Lorin@RickerNet.us>
# Version 4.3, 05/05/2015
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# Common commands for DCL (dcl.rb)
#
# Used by ../projects/ruby/dcl.com and dclrename.rb

module DCLcommand

# See ri FileUtils --
require 'fileutils'

require_relative '../lib/ErrorMsg'

WILDSPLAT = '*'
WILDQUEST = '?'

# ==========

  # See ri FileUtils::cp
  def self.copy( options, operands )
    DCLcommand.parseops( options, operands ) do | src, dst |
      begin
        FileUtils.cp( src, dst,
                      filter( options, [ :preserve, :noop, :verbose ] ) )
      rescue StandardError => e
        fu_rescue( e )
      end
    end
  end  # copy

# ==========

  def self.create( options, fspec )
    DCLcommand.nyi( "CREATE" )
  end  # create

# ==========

  # See ri FileUtils::rm
  def self.delete( options, operands )
    begin
      FileUtils.rm( src, dst,
                    filter( options, [ :force, :noop, :verbose ] ) )
    rescue StandardError => e
      fu_rescue( e )
    end
  end  # delete

# ==========

  def self.directory( options, operands )
    DCLcommand.nyi( "DIRECTORY" )
  end  # directory

# ==========

  def self.purge( options, operands )
    DCLcommand.nyi( "PURGE" )
  end  # purge

# ==========

  # See ri FileUtils::mv
  ## Also see $rby/dclrename.rb
  def self.rename( options, operands )
    DCLcommand.parseops( options, operands ) do | src, dst |
      begin
        FileUtils.mv( src, dst,
                      filter( options, [ :force, :noop, :verbose ] ) )
      rescue StandardError => e
        fu_rescue( e )
      end
    end
  end  # rename

# ==========

  # '$ SEARCH files pattern' --> '$ grep pattern files'
  #
  # This 'SEARCH' command is more powerful than VMS/DCL's, since it uses
  # general regular expressions (regexps) rather than 'simple wildcarded'
  # search-strings... Do quote your '\w(star(get|)|regexp)\w' !!!
  #
  def self.search( options, alloptions, operands )
    starget = operands.pop
    cmd = "/bin/grep --color=always --ignore-case -e '#{starget}' "
    src.each { |s| cmd << " '#{s}'" }
    # for less, honor grep's color output with --raw-control-chars:
    cmd += " | /bin/less --raw-control-chars" if options[:pager] or alloptions[:pager]
    exec( cmd )  # chains, no return...
  end  # search

# ==========

  def self.show( options, what )
    DCLcommand.nyi( "SHOW" )
  end  # show

# ==========

private

  def self.nyi( cmd )
    ErrorMsg.putmsg( msgpreamble = "%#{PROGNAME}-w-nyi",
                     msgtext     = "DCL command '#{cmd}' not yet implemented" )
    exit false
  end  # nyi

  def self.filter( options, legalopts )
    # FileUtils options can be [ :force, :noop, :preserve, :verbose ],
    # but it's different for each method cp, mv, rm, etc. --
    return options.dup.delete_if { |k,v| legalopts.find_index(k).nil? }
  end  # filter

  def self.parseops( options, operands )
    ## TODO: parse any '*.ext' or 'fname.*' and
    ##       set namewild &/or typewild
    ##       accordingly...
    ##       OR? This can be a pattern -> gsub() ???
    ##
    # Decompose the wildcarded rename pattern --
    #   the Last Argument is the pattern ---v
    repat     = File.expand_path( operands.pop )
    dironly   = File.directory?( repat )
    repatdirn = File.dirname( repat ) if dironly
    repatdirn = repatdirn + '/' if repatdirn[-1] != '/'
    repattype = File.extname( repat )

    repatname = File.basename( repat, repattype )
    namewild = repatname.index( WILDSPLAT )
    typewild = repattype.index( WILDSPLAT )
    begin
      $stdout.puts "\nrename-pattern: '#{repat}'"
      pp( operands, $stdout )
      pp( options, $stdout )
    end if options[:debug] > DBGLVL0

    operands.each_with_index do | f, idx |
      src     = File.expand_path( f )
      srcdirn = File.dirname( src )
      srctype = File.extname( src )
      srcname = File.basename( src, srctype )

      dstname  = namewild ? srcname : repatname
      dstname += typewild ? srctype : repattype
      if File.directory?( repat )
        dst = File.join( repatdirn, "#{srcname + srctype}" )
      else
        dst = File.join( repatdirn, dstname )
      end

      if ! File.exists?( dst ) || options[:force]
        $stderr.puts "\##{idx+1}: '#{src}' --> '#{dst}'" if options[:debug] > DBGLVL0
        yield src, dst
      else
        ErrorMsg.putmsg( msgpreamble = "%#{PROGNAME}-e-noclobber",
                         msgtext     = "file '#{dst}' already exists;",
                         msgline2    = "use --force (-F) to supersede it" )
      end
    end  # operands.each
  end  # parseops

  def self.fu_rescue( e )
    ErrorMsg.putmsg( "%#{PROGNAME}-e-rescued, #{e}", e.to_s )
    exit false
  end  # fu_rescue

end  # module DCLcommand
