#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# TimeInterval.rb
#
# Copyright © 2014-2016 Lorin Ricker <Lorin@RickerNet.us>
# Version 2.0, 11/26/2016
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require_relative './StringEnhancements'

# Adds a much-needed elapsed method to Time class

# A TimeInterval instance tracks temporal durations (intervals) as measured
# in seconds, with support for formatted output.

class TimeInterval < Time

  @@seconds_in_a = {
      year: 31557600,  # 60 * 60 * 24 * 365.25
     month:  2592000,  # 60 * 60 * 24 * 30
      week:   604800,  # 60 * 60 * 24 *  7
       day:    86400,  # 60 * 60 * 24
      hour:     3600,  # 60 * 60
    minute:       60,
    second:        1
  }.freeze

    @@report_units = {
        year: false,
       month: false,
        week: false,
         day:  true,
        hour:  true,
      minute:  true,
      second:  true,
    }.freeze

  attr_reader :accumulated_interval,
              :start_time
  attr_accessor :end_time

  # Use 'initseconds' to provide an initial interval in seconds
  def initialize( start_ts = Time.now,
                  initseconds = nil,
                  end_ts = nil )
    @start_time = start_ts
    @accumulated_interval = initseconds || 0
    @end_time = end_ts
  end  #  initialize

  def accumulate( interval )
    case interval
    when /(\d{1,3})[ -](\d{1,2})[:.](\d{1,2})[:.](\d\d)/
      i = $1.to_i * @@seconds_in_a[:day]    \
        + $2.to_i * @@seconds_in_a[:hour]   \
        + $3.to_i * @@seconds_in_a[:minute] \
        + $4.to_i * @@seconds_in_a[:second]
    when /(\d{1,2})[:.](\d{1,2})[:.](\d\d)/
      i = $1.to_i * @@seconds_in_a[:hour]   \
        + $2.to_i * @@seconds_in_a[:minute] \
        + $3.to_i * @@seconds_in_a[:second]
    when /(\d{1,2})[:.](\d\d)/
      i = $1.to_i * @@seconds_in_a[:minute] \
        + $2.to_i * @@seconds_in_a[:second]
    when /0?[:.](\d\d)/
      i = $1.to_i * @@seconds_in_a[:second]
    when /(\d+)/
      i = $1.to_i * @@seconds_in_a[:minute]
    else
      i = 0
      puts "%TimeInterval-e-entry, format error"
    end  # case
    @accumulated_interval += i
    @end_time = @accumulated_interval if ! @end_time
  end  # accumulate

  def to_s
    acc = @accumulated_interval
    s = ""
    # TODO: returns @accumulated_interval as a "d[-| ]hh:mm:ss" string
    return "00:00" if acc == 0
    da, hr, mi, se = 0
    if acc >= @@seconds_in_a[:day]
      da, acc = acc.divmod( @@seconds_in_a[:day] )
      # acc = acc.modulo( @@seconds_in_a[:day] )
      s = sprintf( "%3d ", da )
    else s = "0 "
    end
    if acc >= @@seconds_in_a[:hour]
      hr, acc = acc.divmod( @@seconds_in_a[:hour] )
      # acc = acc.modulo( @@seconds_in_a[:hour] )
      s += sprintf( "%02d", hr )
    else s += "00"
    end
    if acc >= @@seconds_in_a[:minute]
      mi, acc = acc.divmod( @@seconds_in_a[:minute] )
      # acc = acc.modulo( @@seconds_in_a[:minute] )
      s += sprintf( ":%02d", mi )
    else s += ":00"
    end
    if acc >= @@seconds_in_a[:second]
      se, acc = acc.divmod( @@seconds_in_a[:second] )
      # acc = acc.modulo( @@seconds_in_a[:second] )
      s += sprintf( ":%02d", se )
    else s += ":00"
    end
    return s
  end  # to_s

  # Calculate the interval between "start-time" and "now":
  #   started = TimeInterval.now  # inherits now from Time
  #   # ...later ...
  #   started.elapsed
  #   # ...or
  #   endtime = TimeInterval.now
  #   started.elapsed( endtime )
  def elapsed( ended )
      delta = ( ended - @start_time.to_i ).abs.truncate  # don't care about fractional seconds
    incdays = delta >= @@seconds_in_a[:day]
         da = delta / @@seconds_in_a[:day]
      delta = delta % @@seconds_in_a[:day]
         hr = delta / @@seconds_in_a[:hour]
      delta = delta % @@seconds_in_a[:hour]
         mi = delta / @@seconds_in_a[:minute]
         se = delta % @@seconds_in_a[:minute]
    return incdays ?
           sprintf( "%d %02d:%02d:%02d", da, hr, mi, se ) :
           sprintf( "%02d:%02d:%02d", hr, mi, se )
  end  # elapsed

end  # class TimeInterval

class String

  def to_seconds
    # Converts a "d[-| ]hh:mm:ss" string to interval of seconds (integer)
    self
  end  # to_seconds

end  # String

# === Main/test/demo ===
if $0 == __FILE__
  require 'pp'
  require_relative './ANSIseq'
  puts ''.clearscreen
  puts "\n#{'='*3} TimeInterval demo #{'='*30}"
  delay = 7
  starttime = TimeInterval.new( start_ts = Time.now )
  puts starttime
  puts "Sleeping for #{delay} seconds..."
  sleep delay
  starttime.accumulate( delay )
  puts starttime.end_time
  puts starttime.start_time
  puts "elapsed #{ starttime.elapsed( starttime.end_time ) }"
  puts "#{'='*52}"
end
