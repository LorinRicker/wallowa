#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# Rule.rb
#
# Copyright © 2011-2014 Lorin Ricker <Lorin@RickerNet.us>
# Version 2.0, 10/09/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# Create a printable (on terminal display) RULER; called by ruler.rb

# Provides a quick way to "toss up" a horizontal rule for visually
# determining horizontal positions across a terminal display.
#
# An 80-column ruler looks like this (actual display would omit the leading '# '):
#
#     .    |    .    |    .    |    .    |    .    |    .    |    .    |    .    |
#          1         2         3         4         5         6         7         8
# 12345678901234567890123456789012345678901234567890123456789012345678901234567890
#
# A ruler's display expands (or shrinks) to horizontally-fill the current terminal's
# width (number of columns).
#
# The top-left corner of the display is defined to be 1;1 (row;col or line;col).

module Rule

  ABSMAX = 256

  def self.fit_ruler( twidth, s )
    w = [twidth,s.length,ABSMAX].min - 1
    return s[0..w].rstrip
  end  # fit_ruler

  def self.ruleline( twidth, str = '1234567890' )
    s = str * (( twidth / 10 ) + 1)
    return fit_ruler( twidth, s )
  end  # ruleline

  def self.decaline( twidth )
    gap = ' ' * 9
    m   = twidth / 10
    s   = ''
    (1..m).each { |i| s += gap + (i.to_s)[-1] }  # use last digit of value
    return fit_ruler( twidth, s )
  end  # decaline

  def self.ruler( style = :default )
    term_length, term_width = TermChar.terminal_dimensions
    hashmarks = Rule.ruleline( term_width, '    .    |' )
    decades   = Rule.decaline( term_width )
    units     = Rule.ruleline( term_width, '1234567890' )
    ruler     = decades + $/ + units
    case style.to_sym
    when :both, :default
      ruler = hashmarks + $/ + ruler + $/ + hashmarks
    when :before
      ruler = hashmarks + $/ + ruler
    when :after
      ruler = ruler + $/ + hashmarks
    when :none
      ruler # no change to ruler
    else
      $stderr.puts "$%ruler-e-badvalue, error in style value '#{style}'"
      # note: returns nil as method's value...
    end
  end  # ruler

  RULER = Rule.ruler

end  # module
