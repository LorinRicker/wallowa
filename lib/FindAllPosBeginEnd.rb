#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# FindAllPosBeginEnd.rb
#
# Copyright © 2015 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# Add three 'find_all_pos[begin[end]]' instance methods
# to String and to Regexp --

class String

  # 1. Return an array of the begin (start) position of each match:
  def find_all_pos( pat )
    str = self
    mpos = []
    m = i = 0
    m = pat.match( str, i ) { |k| j = k.begin(0); i = j + 1; mpos << j } while m
    return mpos
  end  # find_all_pos

  # 2. Return an array containing elements [begin,end] of matched substrings:
  def find_all_posbegin( pat )
    str = self
    mpos = []
    m = i = 0
    m = pat.match( str, i ) { |k| j = k.offset(0); i = j[0] + 1; mpos << j } while m
    return mpos
  end  # find_all_posbegin

  # 3. Return an array containing elements [begin,end,length] of matched substrings:
  def find_all_posbeginend( pat )
    str = self
    mpos = []
    m = i = 0
    m = pat.match( str, i ) { |k| j = k.offset(0); i = j[0] + 1;
                                  j << j[1] - j[0]; mpos << j    } while m
    return mpos
  end  # find_all_posbeginend

end  # class String

class Regexp

  # 1. Return an array of the begin (start) position of each match:
  def find_all_pos( str )
    str.find_all_pos( self )
  end  # find_all_pos

  # 2. Return an array containing elements [begin,end] of matched substrings:
  def find_all_posbegin( str )
    str.find_all_posbegin( self )
  end  # find_all_posbegin

  # 3. Return an array containing elements [begin,end,length] of matched substrings:
  def find_all_posbeginend( str )
    str.find_all_posbeginend( self )
  end  # find_all_posbeginend

end  # class Regexp

# main -- for testing:
if $0 == __FILE__
  str = "The fox hides in the box full of sox eating lox."
  #       4^                  25^   31^
  puts "str: '#{str}'"
  # Use the literal pattern /f/ as an example --
  # there are three "f"s in the sample source string;
  # see indexes above...
  pat = /f/
  puts "pat: #{pat}"

  # exercise the String methods:
  p str.find_all_pos( pat )           # => [4, 25, 31]
  p str.find_all_posbegin( pat )      # => [[4, 5], [25, 26], [31, 32]]
  p str.find_all_posbeginend( pat )   # => [[4, 5, 1], [25, 26, 1], [31, 32, 1]]
  # exercise the Regexp methods:
  p pat.find_all_pos( str )           # => [4, 25, 31]
  p pat.find_all_posbegin( str )      # => [[4, 5], [25, 26], [31, 32]]
  p pat.find_all_posbeginend( str )   # => [[4, 5, 1], [25, 26, 1], [31, 32, 1]]
end  # main
