#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# TermChar.rb
#
# Copyright © 2012-2017 Lorin Ricker <Lorin@RickerNet.us>
# Version 3.0, 09/12/2016
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# Terminal Characteristics --

module TermChar

  def self.terminal_dimensions( show = nil, os = nil )
    tdim = [ 24, 80 ]  # old VT-100 dimensions, reasonable fallback?
    if os
      whichos = os
    else
      require_relative '../lib/WhichOS'
      whichos = WhichOS.identify_os
    end
    # Determine window/term-screen size as [ LENGTH, WIDTH ]
    case whichos
    when :linux
      if RUBY_VERSION >= '2.0'  # use Ruby's own top-level constant
        require "io/console"
        tdim = IO.console.winsize
      else
        # Hack to get terminal's display dimensions (# of lines & characters) --
        # stty size returns terminal's [length, width] (#lines, #columns):
        tdim = %x{stty size}.split.collect { |td| td.to_i }
      end
    when :vms
      tdim = [ %x{ WRITE sys$output F$GETDVI("TT","TT_PAGE") }.chomp,
               %x{ WRITE sys$output F$GETDVI("TT","DEVBUFSIZ") }.chomp ]
    # when :unix
    # when :windows
    else
      puts "%TermChar-e-NYI, terminal_dimensions not yet implemented for \\#{whichos}\\"
    end  # case whichos
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
