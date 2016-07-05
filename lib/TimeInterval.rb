#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# TimeInterval.rb
#
# Copyright © 2014-2016 Lorin Ricker <Lorin@RickerNet.us>
# Version 2.0, 07/05/2016
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require_relative './StringEnhancements'

# Adds a much-needed elapsed method to Time class

# A TimeInterval instance tracks temporal durations (intervals) as measured
# in seconds, with support for formatted output.

class TimeInterval << Time

  @@seconds_in_a = {
      year: 31557600,  # 60 * 60 * 24 * 365.25
     month:  2592000,  # 60 * 60 * 24 * 30
      week:   604800,  # 60 * 60 * 24 *  7
       day:    86400,  # 60 * 60 * 24
      hour:     3600,  # 60 * 60
    minute:       60,
    second:        1
    }

    @@report_units = {
        year: false,
       month: false,
        week: false,
         day:  true,
        hour:  true,
      minute:  true,
      second:  true,
      }

  attr_reader :accumulated_interval

  # Use 'initseconds' to provide an initial interval in seconds
  def initialize( initseconds = nil )
    @accumulated_interval = initseconds || 0
  end  #  initialize

  def accumulate( str )
    @accumulated_interval += to_seconds( str )
  end  # accumulate

  def to_s
    # returns @accumulated_interval as a "d[-| ]hh:mm:ss" string
  end  # to_s

  # Calculate the interval between "start-time" and "now":
  #   starttime = Time.now
  #   # ...later ...
  #   starttime.elapsed
  #   # ...or
  #   endtime = Time.now
  #   starttime.elapsed( endtime )
  def elapsed( ended = Time.now )
      delta = (ended - self).abs.truncate  # don't care about fractional seconds
    incdays = delta >= seconds_in_a[:day]
         da = delta / seconds_in_a[:day]
      delta = delta % seconds_in_a[:day]
         hr = delta / seconds_in_a[:hour]
      delta = delta % seconds_in_a[:hour]
         mi = delta / seconds_in_a[:minute]
         se = delta % seconds_in_a[:minute]
    return incdays ?
           sprintf( "%d %02d:%02d:%02d", da, hr, mi, se ) :
           sprintf( "%02d:%02d:%02d", hr, mi, se )
  end  # elapsed

end  # class TimeInterval

class String

  def to_seconds
    # Converts a "d[-| ]hh:mm:ss" string to interval of seconds (integer)
  end  # to_seconds

end  # String
