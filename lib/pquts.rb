#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# pquts.rb
#
# Copyright © 2011-2012 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.1, 10/18/2012
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# These are top-level routines (global, class Object)

  # Embellish & label an arg for quts, just returning the string
  def quts( arg, label = "", qchr = '"' )
    begin
      l = label == "" ? "" : label + ": "
      q = qchr
      q = "'" if arg.index(qchr)
      q = "`" if arg.index(qchr) && arg.index("'")
      "#{l}#{q}#{arg}#{q}"
    rescue
      '""'            # when arg turns out to be nil, return empty string
    end
  end  # quts

  # Embellished 'puts' which quotes its argument, optionally labelling it
  def pquts( arg, label = "", qchr = '"' )
    puts quts( arg, label, qchr )
  end  # pquts
