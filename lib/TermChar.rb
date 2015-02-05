#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# TermChar.rb
#
# Copyright © 2012-2015 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.1, 02/04/2015
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# Terminal Characteristics --

module TermChar

  def self.terminal_dimensions( show = nil )
    # Hack to get terminal's display dimensions (# of lines & characters) --
    # stty size returns terminal's [length width] (#lines, #columns):
    tdim = %x{stty size}.split.collect { |w| w.to_i }
    if show
      puts "Terminal width is #{tdim[1]} characters"
      puts "Terminal length is #{tdim[0]} lines"
    end  # if show
    return tdim
  end  # terminal_dimensions

  def self.terminal_height
    terminal_dimensions[0]
  end  # terminal_height

  def self.terminal_width
    terminal_dimensions[1]
  end  # terminal_width

end  # module TermChar
