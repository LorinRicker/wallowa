#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# TermChar.rb
#
# Copyright © 2012-2016 Lorin Ricker <Lorin@RickerNet.us>
# Version 2.2, 01/30/2016
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# Terminal Characteristics --

module TermChar

  def self.terminal_dimensions( show = nil )
    if RUBY_VERSION >= '2.0'
      require "io/console"
      tdim = IO.console.winsize
    else
      # Hack to get terminal's display dimensions (# of lines & characters) --
      # stty size returns terminal's [length width] (#lines, #columns):
      tdim = %x{stty size}.split.collect { |td| td.to_i }
    end
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

  def self.every_window_change_event
    begin
      puts ">>> ready to trap..."
      trap( 'WINCH' ) do
        yield
      end
      sleep
    rescue Interrupt => e
      raise SystemExit
      return nil
    end
  end  # each_window_change_event

end  # module TermChar
