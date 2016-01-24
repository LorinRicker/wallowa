#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# Rule.rb
#
# Copyright © 2011-2016 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.1, 02/05/2015
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
#     .    |    .    |    .    |    .    |    .    |    .    |    .    |    .    |
#
# A ruler's display expands (or shrinks) to horizontally-fill the current terminal's
# width (number of columns).
#
# The top-left corner of the display is defined to be 1;1 (row;col or line;col).

module Rule

  ABSMAX = 256  # reasonable upper limit on ruler length

  def self.fit_ruler( twidth, str )
    w = [twidth,str.length,ABSMAX].min - 1
    return str[0..w].rstrip
  end  # fit_ruler

  def self.ruleline( twidth, strlen, str = '1234567890' )
    return fit_ruler( twidth, str * (( twidth / strlen ) + 1) )
  end  # ruleline

  def self.decaline( twidth, strlen )
    gap = ' ' * (strlen-1)
    m   = twidth / strlen
    str = ''
    (1..m).each { |i| str += gap + (i.to_s)[-1] }  # use last digit of value
    return fit_ruler( twidth, str )
  end  # decaline

  def self.ruler( style        = :default,
                  unitsstr     = '1234567890',
                  rulemarksstr = '    .    |' )
    strlen = unitsstr.length
    raise ArgumentError,   # unitsstr and rulemarksstr must be == length
         "ruler components length mismatch" if strlen != rulemarksstr.length
    term_length, term_width = TermChar.terminal_dimensions
    units     = Rule.ruleline( term_width, strlen, unitsstr )
    rulemarks = Rule.ruleline( term_width, strlen, rulemarksstr )
    decades   = Rule.decaline( term_width, strlen )
    ruler     = decades + $/ + units
    case style.to_sym
    when :both, :default  # $/ is "current" record (line) separator...
      ruler = rulemarks + $/ + ruler + $/ + rulemarks
    when :before
      ruler = rulemarks + $/ + ruler
    when :after
      ruler = ruler + $/ + rulemarks
    when :none
      ruler # no change to ruler
    else
      raise ArgumentError, "error in style value '#{style}'"
      # note: returns nil as method's value...
    end
  end  # ruler

  RULER = Rule.ruler

end  # module
