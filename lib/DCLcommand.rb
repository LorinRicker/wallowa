#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# DCLcommand.rb
#
# Copyright © 2015 Lorin Ricker <Lorin@RickerNet.us>
# Version 4.7, 08/07/2015
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
    DCLcommand.parse2ops( options, operands ) do | src, dst |
      begin
        FileUtils.cp( src, dst,
                      filter( options, [ :preserve, :noop, :verbose ] ) )
      rescue StandardError => e
        fu_rescue( e )
      end
    end
  end  # copy

# ==========

  def self.create( options, operands )
    DCLcommand.parse1ops( options, operands ) do | fil |
      begin
        FileUtils.touch( fil,
                         filter( options, [ :noop, :verbose ] ) )
      rescue StandardError => e
        fu_rescue( e )
      end
    end
  end  # create

# ==========

  # See ri FileUtils::rm
  def self.delete( options, operands )
    DCLcommand.parse1ops( options, operands ) do | fil |
      begin
        FileUtils.rm( fil,
                      filter( options, [ :force, :noop, :verbose ] ) )
      rescue StandardError => e
        fu_rescue( e )
      end
    end
  end  # delete

# ==========

  def self.directory( options, operands )
    DCLcommand.nyi( "DIRECTORY" )
  end  # directory

# ==========

  def self.purge( options, operands )
    # Probably will never build/implement this, as ;version numbers
    #   are completely foreign to anything but VMS...
    #   but if we did, we'd use:
    # DCLcommand.parse1ops( options, operands ) do | fil | ...
    DCLcommand.nyi( "PURGE" )
  end  # purge

# ==========

  # See ri FileUtils::mv
  ## Also see $rby/dclrename.rb
  def self.rename( options, operands )
    DCLcommand.parse2ops( options, operands ) do | src, dst |
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
    starget = operands.pop  # last arg-word is what we're searching for
    cmd = "/bin/grep --color=always --ignore-case --regexp='#{starget}' "
    operands.each do |op|
      Dir.glob( op ).each { | s | cmd << " '#{s}'" }
    end
    # for less, honor grep's color output with --raw-control-chars:
    cmd += " | /bin/less --raw-control-chars" if options[:pager] or alloptions[:pager]
    puts cmd if options[:verbose]
    exec( cmd ) if ! options[:noop]  # chains, no return...
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

  def self.globwildcards
    # legal glob wildcard characters, defined in one place
    /[\*\?\[\{]+/
  end  # globwildcards

  def self.expandwild( elem )
    # legal glob wildcard characters
    if globwildcards =~ elem
      Dir.glob( elem )  # returns an array of filespecs
    else
      [ elem ]          # construct and return an array containing the filespec
    end
  end  # expandwild

  def self.parse1ops( options, operands )
    ##
    # Determine who called me? -- This is second-most-recent entry
    #   of the caller (method) stack (eliminated the first/parseNops
    #   with caller(1) ... the one wanted is array element [0]...);
    #   future-proof against changes to `name' with [`'"] ...
    cb = /:in [`'"]([a-z]+)[`'"]/.match( caller(1)[0] )
    calledby = cb[1]  # first group = $1

    # In this semantic, want to check that target file:
    #   a) does _not_ yet exist if create/touch-ing;
    #   b) _does_ exist if deleting it...
    # unless --force (-F)...
    if calledby.to_sym == :create
      filecond = lambda { | f | ! File.exists?( f ) }
      msgabbr  = 'exists'
      msgcond  = 'already exists'
    else
      filecond = lambda { | f | File.exists?( f ) }
      msgabbr  = 'fnf'
      msgcond  = 'not found'
    end

    idx = 1  # file counter
    operands.each do | elem |
      expandwild( elem ).each do | fl |
        # The user can optionally --force (-F) override:
        if filecond.call( fl ) || options[:force]
          $stderr.puts "#{calledby} \##{idx}: '#{fl}'" if options[:debug] > DBGLVL0
          yield fl
          idx += 1
        else
          ErrorMsg.putmsg( msgpreamble = "%#{PROGNAME}-e-#{msgabbr}",
                           msgtext     = "file '#{fl}' #{msgcond}" )
        end
      end  # expandwild( elem ).each
    end  # operands.each
  end  # parse1ops

  def self.parse2ops( options, operands )
    # Determine who called me? -- This is second-most-recent entry
    #   of the caller (method) stack (eliminated the first/parseops
    #   with caller(1) ... the one wanted is array element [0]...);
    #   future-proof against changes to `name' with [`'"] ...
    cb = /:in [`'"]([a-z]+)[`'"]/.match( caller(1)[0] )
    calledby = cb[1]  # first group = $1

    patname = pattype = ''

    # Decompose the wildcarded rename pattern --
    #   the Last Argument is the pattern ---v
    pat      = File.expand_path( operands.pop )
    dironly  = File.directory?( pat )
    if dironly
      patdirn  = pat
      patdirn += '/' if patdirn[-1] != '/'
    else
      patdirn  = File.dirname( pat )
      pattype  = File.extname( pat )
      patname  = File.basename( pat, pattype )
      namewild = globwildcards =~ patname
      typewild = globwildcards =~ pattype
      typewild = namewild if pattype == ''        # honor '*' as '*.*'
    end

    idx = 1  # file counter
    operands.each do | elem |
      expandwild( elem ).each do | f |
        src     = File.expand_path( f )
        srcdirn = File.dirname( src )
        srctype = File.extname( src )
        srcname = File.basename( src, srctype )

        dstname  = namewild ? srcname : patname
        dstname += typewild ? srctype : pattype
        if dironly
          dst = File.join( patdirn, "#{srcname + srctype}" )
        else
          dst = File.join( patdirn, dstname )
        end

        # The user can optionally --force (-F) override:
        if ! File.exists?( dst ) || options[:force]
          $stderr.puts "#{calledby} \##{idx}: '#{src}' -> '#{dst}'" if options[:debug] > DBGLVL0
          yield src, dst
          idx += 1
        else
          ErrorMsg.putmsg( msgpreamble = "%#{PROGNAME}-e-noclobber",
                           msgtext     = "file '#{dst}' already exists;",
                           msgline2    = "use --force (-F) to supersede it" )
        end
      end  # expandwild( elem ).each
    end  # operands.each
  end  # parse2ops

  def self.fu_rescue( e )
    ErrorMsg.putmsg( "%#{PROGNAME}-e-rescued, #{e}", e.to_s )
    exit false
  end  # fu_rescue

end  # module DCLcommand
