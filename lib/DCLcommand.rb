#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# DCLcommand.rb
#
# Copyright © 2015-2017 Lorin Ricker <Lorin@RickerNet.us>
# Version 5.11, 05/21/2017
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# Common commands for DCL (dcl.rb)
#
# Used by ../projects/ruby/dcl.com and dclrename.rb

module DCLcommand

WILDSPLAT = '*'
WILDQUEST = '?'

require_relative '../lib/GetPrompted'

# ==========

def self.fileCommands( action, operands, options )

  # Conditional: needed only for these file commands --
  # See ri FileUtils --
  require 'fileutils'

  dcloptions, operands = parse_dcl_qualifiers( operands )
  options.merge!( dcloptions )

  # Commands:
  case action.to_sym              # Dispatch the command-line action;
                                  # invoking symlink's name is $0 ...
  when :copy
    DCLcommand.copy( options, operands )

  when :create
    DCLcommand.create( options, operands )

  when :delete
    DCLcommand.delete( options, operands )

  when :directory
    DCLcommand.directory( options, operands )

  # when :purge  # -- removed: likely never to be implemented
  #   DCLcommand.purge( options, operands )

  when :rename
    DCLcommand.rename( options, operands )

  when :search
    DCLcommand.search( options, operands )

  when :show
    DCLcommand.show( options, operands )

  else
    $stderr.puts "%#{PROGNAME}-e-badcommand, not a DCL command: '#{action}'"
    exit false
  end  # case action.to_sym

end  # fileCommands

# ==========
  # See ri FileUtils::cp
  def self.copy( options, operands )
    doall = false
    DCLcommand.parse2ops( options, operands ) do | src, dst |
      confirmed, doall = askordo( options[:confirm], doall,
                                  "Copy #{src} to #{dst}" )
      begin
        FileUtils.cp( src, dst,
                      filter( options,
                             [ :preserve, :noop, :verbose ] )
                    ) if confirmed
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
    doall = false
    DCLcommand.parse1ops( options, operands ) do | fil |
      confirmed, doall = askordo( options[:confirm], doall,
                                  "Delete #{fil}" )
      begin
        FileUtils.rm( fil,
                      filter( options,
                              [ :force, :noop, :verbose ] )
                    ) if confirmed
      rescue StandardError => e
        fu_rescue( e )
      end
    end
  end  # delete

# ==========

  def self.directory( options, operands )
    # Just a handoff to the partner script dir.rb (and lib/DirectoryVMS.rb) --
    # ...mimics the anti-globbing behavior of bash function ResetGlobbing, too!
    cmd = "set -f ; #{BINPATH}/dir #{operands.join( ' ' )} ; set +f"
    puts cmd.bold if options[:debug] >= 1
    exec( cmd ) if ! options[:noop]  # chains, no return...
  end  # directory

# ==========

  # def self.purge( options, operands )  # -- removed: likely never to be implemented
  #   # Probably will never build/implement this, as ;version numbers
  #   #   are completely foreign to anything but VMS...
  #   #   but if we did, we'd use:
  #   # DCLcommand.parse1ops( options, operands ) do | fil | ...
  #   DCLcommand.nyi( "PURGE" )
  # end  # purge

# ==========
  # See ri FileUtils::mv
  ## Also see $rby/dclrename.rb
  def self.rename( options, operands )
    doall = false
    DCLcommand.parse2ops( options, operands ) do | src, dst |
      # Convert case and whitespace options can be used together (one of each):
      case options[:case]
      when :lower
        dst = File.join( File.dirname(dst), File.basename(dst).downcase )
      when :upper
        dst = File.join( File.dirname(dst), File.basename(dst).upcase )
      when :camel, :capital
        dst = dst.split( '_' ).collect( &:capitalize ).join
      when :snake
        dst = dst.gsub( /::/, '/' )
                    .gsub( /([A-Z]+)([A-Z][a-z])/,'\1_\2' )
                    .gsub( /([a-z\d])([A-Z])/,'\1_\2' )
                    .tr( "-", "_" )
                    .downcase
      when :underscores
        dst = DCLcommand.squeeconvert( dst, ' ', '_' )
      end  # case options[:case]
      # Convert case and whitespace options can be used together (one of each):
      case options[:whitespace]
      when :spaces
        dst = DCLcommand.squeeconvert( dst, '_', ' ' )
      when :compress
        dst = DCLcommand.squeecompress( dst, ' -_' )
      when :collapse
        dst = DCLcommand.squeecollapse( dst, ' ' )
      end  # case options[:whitespace]
      if options[:fnprefix]   # glue a prefix string to basename
                              # 'foo.txt' -> 'PREFIXfoo.txt'
        dst = File.join( File.dirname( src ),
                         options[:fnprefix] + File.basename( src ) )
        puts "dst: \"#{dst}\""
      end  # if
      # Use any combination of prefix and suffix operations as needed:
      if options[:fnsuffix]   # glue a suffix string to basename
                              # 'foo.txt' -> 'fooSUFFIX.txt'
        xtn = File.extname( src )
        bsn = File.basename( src, xtn )
        dst = File.join( File.dirname( src ),
                         bsn + options[:fnsuffix] + xtn )
        puts "dst: \"#{dst}\""
      end  # if
      if options[:xtprefix]   # glue a prefix string to extension
                              # 'foo.txt' -> 'foo.PREFIXtxt'
        xtn = File.extname( src )
        bsn = File.basename( src, xtn )
        xtn = '.' + options[:xtprefix] + xtn[1..xtn.size]
        dst = File.join( File.dirname( src ), bsn + xtn )
        puts "dst: \"#{dst}\""
      end  # if
      if options[:xtsuffix]   # glue a suffix string to extension
                              # 'foo.txt' -> 'foo.txtSUFFIX'
        dst = File.join( File.dirname( src ),
                         File.basename( src ) + options[:xtsuffix] )
        puts "dst: \"#{dst}\""
      end  # if
      confirmed, doall = askordo( options[:confirm], doall,
                                  "Rename #{src} to #{dst}" )
      begin
        FileUtils.mv( src, dst,
                      filter( options,
                              [ :force, :noop, :verbose ] )
                    ) if confirmed
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
  def self.search( options, operands )
    starget = operands.pop  # last arg-word is what we're searching for
    cmd = "/bin/grep --color=always --ignore-case --regexp='#{starget}' "
    operands.each do |op|
      Dir.glob( op ).each { | s | cmd << " '#{s}'" }
    end
    # for less, honor grep's color output with --raw-control-chars:
    cmd += " | /bin/less --raw-control-chars" if options[:pager]
    puts cmd.bold if options[:debug] >= 1
    exec( cmd ) if ! options[:noop]  # chains, no return...
  end  # search

# ==========

  # SHOW item
  #
  # Maps a few common DCL SHOW commands to reasonable bash analogues
  # or to home-made command functions.
  #
  def self.show( options, what )
    case what[0][0..2].to_sym
    when :def  # SHOW DEFAULT
      %x{ /bin/pwd }
    when :dev  # SHOW DEVICE
      %x{ di -t -fSbcvpaTM -xtmpfs ; echo '' ; lsblk }
    when :log  # SHOW LOGICAL
      ErrorMsg.putmsg( msgpreamble = "%#{PROGNAME}-e-NYI,",
                       msgtext     = " SHOW LOGICAL not yet implemented" )
      exit false
      # %x{...} is a plain (non-bash/etc) subprocess which executes a 'command',
      # which is not a shell (bash/etc) operation... bash/shell things like all
      # built-ins (e.g., alias) and functions (e.g., logicals) cannot be invoked
      # in this way!
      # So this has to invoke `bash --rcfile xxx.sh`  -- where xxx.sh is a
      # dynamically created script (named pipe?) to invoke selected ~/bin/login
      # scripts followed by the desired SHOW LOGICAL/SYMBOL action...
      # >>> This is likely a decent enough demonstration of concept, but is
      #     NOT likely very portable to other users!
      lnms = ""
      what[1..what.size].each { |w| lnms += " #{w}" }
      %x{ logicals #{lnms} }
    when :mem  # SHOW MEMORY
      %x{ free -mtl }
    when :sym  # SHOW SYMBOL
      ErrorMsg.putmsg( msgpreamble = "%#{PROGNAME}-e-NYI,",
                       msgtext     = " SHOW SYMBOL not yet implemented" )
      exit false
      # See comment under SHOW LOGICAL above!...
      %x{ alias | /bin/egrep --color -i #{what[1]} }
    when :sys  # SHOW SYSTEM
      require_relative '../lib/TermChar'
      twid = TermChar.terminal_width
      %x{ ps -e --format pid,euser,%cpu,%mem,rss,stat,args --width #{twid} }
    when :ter  # SHOW TERMINAL
      %x{ /home/lorin/bin/termchar }
    when :tim  # SHOW TIME
      %x{ /bin/date +'%d-%b-%Y %T' }
    else
      ErrorMsg.putmsg( msgpreamble = "%#{PROGNAME}-e-show,",
                       msgtext     = " no such item to show: #{what[0]}" )
      exit false
    end.lines { |s| puts s }
  end  # show

# ==========

private

  # Strip leading/trailing whitespace from both filename and extension
  # components of basename, squeeze any runs of +fromch+ to single instances,
  # then substitute +toch+ for all +fromch+, reassemble --
  def self.squeeconvert( dst, fromch = ' ', toch = '_' )
    fnm = File.basename( dst, '.*' ).strip.squeeze( fromch )
    ext = File.extname( dst )
    dot = ext[0] == '.'
    ext = ext[1..-1].strip.squeeze( fromch ) if dot
    ext = ext.gsub( fromch, toch ).strip
    fnm = fnm.gsub( fromch, toch ).strip
    fnm << '.' << ext if dot
    File.join( File.dirname( dst ), fnm )
  end  # squeeconvert

  # Strip leading/trailing whitespace from both filename and extension
  # components of basename, squeeze any runs of +fromch+ to single instances,
  # reassemble --
  def self.squeecompress( dst, squishch = ' -_' )
    fnm = File.basename( dst, '.*' ).strip.squeeze( squishch )
    ext = File.extname( dst )
    dot = ext[0] == '.'
    ext = ext[1..-1].strip.squeeze( squishch ) if dot
    fnm << '.' << ext if dot
    File.join( File.dirname( dst ), fnm )
  end  # squeecompress

  # Collapse all whitespace from both filename and extension
  # components of basename, reassemble --
  def self.squeecollapse( dst, scrunch = ' ' )
    fnm = File.basename( dst, '.*' ).gsub( scrunch, '' )
    ext = File.extname( dst )
    dot = ext[0] == '.'
    ext = ext[1..-1].gsub( scrunch, '' ) if dot
    fnm << '.' << ext if dot
    File.join( File.dirname( dst ), fnm )
  end  # squeecompress

  def self.askordo( confirm, doall, prompt )
    if ( confirm and not doall )
      confirmprompted( prompt )
    else [ true, doall ]
    end
  end  # askordo

  def self.parse_dcl_qualifiers( argvector )
    dcloptions = Hash.new
    fspecs     = []
    pat        = /^\/(LOG|CON[FIRM]*|PAG[E]*)$/i
    argvector.each do | a |
      if pat.match( a )
        # A DCL qualifier /LOG or /CON[FIRM] or /PAG[E]: record it...
        case $1[0..2].downcase
        when 'log' then dcloptions[:verbose] = true
        when 'con' then dcloptions[:confirm] = true
        when 'pag' then dcloptions[:pager]   = true
        end  # case
      else
        # A file-spec, copy it...
        fspecs << a
      end
    end
    return [ dcloptions, fspecs ]
  end  # parse_dcl_qualifiers

  def self.confirmprompted( prompt )
    response = getprompted( "#{prompt} (yes,No,all,quit)", "N" )
    case response[0].downcase
    when 'a'
      return [ true, true ]    # do all the rest...
    when 'y'
      return [ true, false ]   # and keep asking...
    when 'n'
      return [ false, false ]  # and keep asking...
    end  # case response.downcase
  end  # confirmprompted

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

  def self.nyi( cmd )
    ErrorMsg.putmsg( msgpreamble = "%#{PROGNAME}-w-nyi",
                     msgtext     = "DCL command '#{cmd}' not yet implemented" )
    exit false
  end  # nyi

end  # module DCLcommand
