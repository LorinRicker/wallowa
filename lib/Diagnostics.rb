#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# Diagnostics.rb
#
# Copyright © 2014 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.4, 08/29/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

require 'pp'
require_relative 'ANSIseq'
require_relative 'TermChar'

module Diagnostics

  class Code

    def initialize( colorize = nil, ralign = true, outchan = STDERR )
      @colorize  = colorize
      @ralign    = ralign
      @outchan   = outchan
      @termwidth = TermChar.terminal_width
    end  # initialize

    # Call: mycode.trace( :var1 => var1 [, :var2 => var2 ]... )
    #   or: mycode.trace( var1: var1 [, var2: var2 ]... )
    def trace( var )
      var.each do | vkey, valu |
        kstr = "·>>> #{vkey}: "
        vstr = "#{valu.inspect}"
        if kstr.length + vstr.length < @termwidth
          str = kstr + vstr
        else
          str = kstr    + vstr.split(',')[0].strip +
                " ··· " + vstr.split(',')[-1].strip
        end
        sln = str.length
        str = str.bold.color(@colorize) if @colorize
        str = ' '*[@termwidth-sln,0].max + str if @ralign
        begin
          @outchan.puts str
        rescue IOError => e
          bailout( e, 'trace' )
        end
      end
    end  # trace

    # Call: mycode.diagnose( var, "in <methname>", __LINE__ )
    def diagnose( obj, label = nil, lineno = nil )
      here = label ? " #{label}" : ""
      here = "#{here} at line:#{lineno}" if lineno
      str = "#{'='*8} #{self.class.name}#{here} #{'='*8}"
      sln = str.length
      str = str.bold.color(@colorize) if @colorize
      begin
        @outchan.puts str
        printf( "<%s, len:%d - %x>\n", obj.class, obj.size, obj.object_id )
        @outchan.puts "object is a member of the #{obj.class} class"
        pp( obj, @outchan, @termwidth )
        str = '='*sln
        str = str.bold.color(@colorize) if @colorize
        @outchan.puts str
      rescue IOError => e
        bailout( e, 'diagnose' )
      end
    end  # diagnose

    private
    def bailout( e, m = 'trace' )
      s = "%Diagnostics::Code.#{m}-E-IOERROR, error on #{m} output"
      $stderr.puts s
      $stderr.pp e
      $stderr.print e.backtrace.join( "\n" )
      exit true
    end

  end  # class Code

end  # module Diagnostics
