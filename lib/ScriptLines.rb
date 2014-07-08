#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# Ruby Cookbook: ScriptLines.rb
# Version 0.5, 10/22/2012
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# A ScriptLines instance analyzes a Ruby script and maintains counters
# for the total numbers of lines, lines of code, comments, etc.

require_relative 'ANSIseq'

class ScriptLines

  attr_reader :name
  attr_accessor :bytes, :lines, :codelines, :comments

  HEAD_FORMAT = "   %5s %8s %7s %10s   %s".bold.underline
  DATA_FORMAT = "%8s %8s %7s %10s : %s"

  def self.headline
    sprintf HEAD_FORMAT, "Bytes", "Lines", "Code", "Comments", "File"
  end  # self.headline

  # The 'name' argument is usually a filename
  def initialize( name )
    @name      = name
    @bytes     = 0
    @lines     = 0
    @codelines = 0
    @comments  = 0
  end  #  initialize

  # Iterate over all the lines in io (a file or a string),
  # analyze them and increase counter attributes appropriately.
  def read( io )
    in_multiline_comment = false
    io.each { | line |
      @lines += 1
      @bytes += line.size
      case line
      when /^=begin(\s|$)/
        in_multiline_comment = true
        @comments += 1
      when /^=end(\s|$)/
        @comments =+ 1
        in_multiline_comment = false
      when /^\s*#/
        @comments += 1
      when /^\s*$/
        # empty or whitespace-only line
      else
        if in_multiline_comment
          @comments += 1
        else
          @codelines += 1
        end
      end  # case
    }  # io.each
  end  # read

  # Get a new ScriptLines instance whose counters hold
  # the sum of self and other:
  def +( other )
    sum = self.dup
    sum.bytes     += other.bytes
    sum.lines     += other.lines
    sum.codelines += other.codelines
    sum.comments  += other.comments
    sum
  end  # +

  # Get a formatted string containing all counter numbers
  # and the name of this instance:
  def to_s
    sprintf DATA_FORMAT,
            @bytes, @lines, @codelines, @comments, @name
  end  # to_s

end  # class ScriptLines
