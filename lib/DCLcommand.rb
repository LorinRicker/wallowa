#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# DCLcommand.rb
#
# Copyright © 2015 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.0, 05/01/2015
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# Common commands for DCL (dcl.rb)
#
# Used by ../projects/ruby/dcl.com and dclrename.rb

module DCLcommand

def self.rename( operands, options )
  # operands is an array, e.g. ARGV (or a derived subset thereof)

  opts = options.dup.delete_if { |k,v| FUOPTS.find_index(k).nil? }

  # decompose the rename pattern
  repat     = File.expand_path( operands.pop )  # last argument is the rename pattern
  repatdirn = File.directory?( repat ) ? repat + '/' : File.dirname( repat )
  repattype = File.extname( repat )
  repatname = File.basename( repat, repattype )
  options[:namewild] = repatname.index( WILDSPLAT )
  options[:typewild] = repattype.index( WILDSPLAT )
  begin
    $stdout.puts "\nrename-pattern: '#{repat}'"
    pp( operands, $stdout )
    pp( opts, $stdout )
    pp( options, $stdout )
  end if options[:debug] > DBGLVL0

  # TODO: parse any '*.ext' or 'fname.*' and
  #       set options[:namewild] &/or options[:typewild]
  #       accordingly...
  #       OR? This can be a pattern -> gsub() ???

  operands.each_with_index do | f, idx |
    src     = File.expand_path( f )
    srcdirn = File.dirname( src )
    srctype = File.extname( src )
    srcname = File.basename( src, srctype )

    dstname  = options[:namewild] ? srcname : repatname
    dstname += options[:typewild] ? srctype : repattype
    if File.directory?( repat )
      dst = File.join( repatdirn, "#{srcname + srctype}" )
    else
      dst = File.join( repatdirn, dstname )
    end
    if File.exists?( dst ) && ! options[:force]
      ErrorMsg.putmsg( msgpreamble = "%#{PROGNAME}-e-noclobber,",
                       msgtext     = "file '#{dst}' already exists;",
                       msgline2    = "use --force (-F) to supersede it" )
    else
      $stderr.puts "file \##{idx+1}: '#{src}' --> '#{dst}'" if options[:debug] > DBGLVL0
      FileUtils.mv( src, dst, opts )
    end
  end  # operands.each

end  # rename

end  # module DCLcommand
