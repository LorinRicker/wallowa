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

  SEC_IN_MIN = 60
  SEC_IN_HR  = SEC_IN_MIN * 60
  SEC_IN_DAY = SEC_IN_HR * 24

  @seconds_in_a = {
      year: 31557600,
     month:  2592000,
      week:   604800,
       day:    86400,
      hour:     3600,
    minute:       60,
    second:        1
    }

    @report_units = {
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

  def seconds_in( str )
    # xxx
  end  # seconds_in

  def accumulate( str )
    @accumulated_interval += seconds_in( str )
  end  # accumulate

  def to_s
    # xxx
  end  # to_s

  def elapsed( ended = Time.now )
      delta = (ended - self).abs.truncate  # don't care about fractional seconds
    incdays = delta >= SEC_IN_DAY
         da = delta / SEC_IN_DAY
      delta = delta % SEC_IN_DAY
         hr = delta / SEC_IN_HR
      delta = delta % SEC_IN_HR
         mi = delta / SEC_IN_MIN
         se = delta % SEC_IN_MIN
    return incdays ?
           sprintf( "%d %02d:%02d:%02d", da, hr, mi, se ) :
           sprintf( "%02d:%02d:%02d", hr, mi, se )
  end  # elapsed

end  # class TimeInterval
