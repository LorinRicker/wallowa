#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# TimeInterval.rb
#
# Copyright © 2014-2017 Lorin Ricker <Lorin@RickerNet.us>
# Version 3.3, 01/19/2017
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

  attr_reader :accumulated_seconds,
              :start_time
  attr_accessor :end_time

  # Use 'initseconds' to provide an initial interval in seconds
  def initialize( opts = nil,
                  start_ts = Time.now,
                  initseconds = nil,
                  end_ts = nil )
    @interval_stack = []
    @start_time = start_ts
    @accumulated_seconds = initseconds || 0
    @end_time = end_ts
    @opts = opts
    pp @opts if @opts[:verbose]
  end  #  initialize

  def parse_interval( interval )
    case interval.to_s
    when /(\d{1,3})[ -](\d{1,2})[:.](\d{1,2})([:.](\d\d))?/
      i = $1.to_i * @@seconds_in_a[:day]    \
        + $2.to_i * @@seconds_in_a[:hour]   \
        + $3.to_i * @@seconds_in_a[:minute] \
        + $5.to_i * @@seconds_in_a[:second]
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
      exit false
    end  # case
    puts "interval: '#{interval}' or #{i} seconds" if @opts[:verbose]
    return i
  end

  def accumulate( interval )
    seconds = parse_interval( interval )
    case @opts[:operator]
    when :add, :plus
      @end_time = @start_time + seconds
      @accumulated_seconds += seconds
    when :subtract, :minus
      @end_time = @start_time - seconds
      @accumulated_seconds -= seconds
    end  # case
    @interval_stack.push( interval )
    if @opts[:verbose]
      puts "@interval_stack:"
      pp @interval_stack
    end
    self.format_interval
  end  # accumulate

  def undo
    last_interval = @interval_stack.pop
    if @opts[:verbose]
      puts "@interval_stack:"
      pp @interval_stack
    end
    case @opts[:operator]
    when :add, :plus
      @accumulated_seconds -= parse_interval( last_interval )
    when :subtract, :minus
      @accumulated_seconds += parse_interval( last_interval )
    end  # case
     self.to_s
  end

  def format_interval
    return "  0 00:00:00" if @accumulated_seconds == 0
    s = ""
    acc = @accumulated_seconds
    da, hr, mi, se = 0
    if acc >= @@seconds_in_a[:day]
      da, acc = acc.divmod( @@seconds_in_a[:day] )
      # acc = acc.modulo( @@seconds_in_a[:day] )
      s = sprintf( "%3d ", da )
    else s = "  0 "
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
  end  # format_interval

  def to_s
    self.format_interval
  end

  # Calculate the interval between "start-time" and "now":
  #   started = TimeInterval.now  # inherits now from Time
  #   # ...later ...
  #   started.elapsed
  #   # ...or
  #   endtime = TimeInterval.now
  #   started.elapsed( endtime )
  def elapsed( ended )
      delta = ( ended.to_i - @start_time.to_i ).abs.truncate  # don't care about fractional seconds
    incdays = delta >= @@seconds_in_a[:day]
    puts "delta: #{delta}   incdays: #{incdays}   @start_time.to_i: #{@start_time.to_i} / ended: #{ended}"
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
  puts String.clearscreen
  puts "\n#{'='*3} TimeInterval demo #{'='*30}"
  options = { :operator => :add,
              :start    => nil,
              :prompt   => false,
              :noop     => false,
              :verbose  => false,
              :debug    => 0,
              :about    => false
            }
  delay = ARGV[0] ? ARGV[0].to_i : 3  # in seconds
  delaystr = sprintf( "00:%02d", delay )
  starttime = TimeInterval.new( opts = options, start_ts = Time.now )
  puts "Sleeping for #{delaystr} seconds..."
  sleep delay
  starttime.accumulate( delaystr )  # bumps starttime.end_time by delay seconds
  puts "start_time: #{starttime.start_time}"
  puts "  end_time: #{starttime.end_time}"
  puts "   elapsed: #{ starttime.elapsed( starttime.end_time ) }"
  puts "#{'='*52}"
end
