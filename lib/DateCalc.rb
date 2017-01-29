#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# DateCalc.rb
#
# Copyright © 2012-2017 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.1, 10/23/2012
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require 'date'
require 'time'
require_relative 'ANSIseq'

class DateCalc

  SEC_IN_DAY = 60 * 60 * 24
  MIN_IN_DAY = 60 * 24

  def self.pluraldays( nd )
    "#{nd} day#{ nd.to_i != 1 ? "s" : "" }"
  end  # ndays

  def self.pdate( d )
    d.strftime( "%B %d %Y" )
  end  # pdate

  def self.days_after( nd, dt = "", report = false )
    nd = "0" if nd == ""
    d1 = dt != "" ? Time.parse( dt ) : Time.now
    sd = dt != "" ? pdate(d1) : "today"
    td = d1 + ( nd.to_i * SEC_IN_DAY )
    puts "#{pluraldays(nd)} after #{sd} is " + "#{pdate(td)}".bold if report
    "#{pdate(td)}"
   end  # days_after

  def self.days_before( nd, dt = "", report = false )
    nd = "0" if nd == ""
    d1 = dt != "" ? Time.parse( dt ) : Time.now
    sd = dt != "" ? pdate(d1) : "today"
    td = d1 - ( nd.to_i * SEC_IN_DAY )
    puts "#{pluraldays(nd)} before #{sd} is " + "#{pdate(td)}".bold if report
    "#{pdate(td)}"
  end  # days_before

  def self.days_between( dt1, dt2, report = false )
    d1 = dt1 != "" ? Time.parse( dt1 ) : Time.now
    d2 = dt2 != "" ? Time.parse( dt2 ) : Time.now
    nd = ( ( d2 - d1 ) / SEC_IN_DAY ).round
    if nd < 0
      puts "#{pluraldays(nd.abs)}".bold + " between #{pdate(d2)} and #{pdate(d1)}" if report
    else
      puts "#{pluraldays(nd)}".bold + " between #{pdate(d1)} and #{pdate(d2)}" if report
    end
    "#{nd} days"
  end  # days_between

  def self.days_until( dt, report = false )
    td = DateCalc.thisday( "today" ).to_s
    days_between( td, dt, report )
  end  # days_until

  def self.thisday( dt )
    # "today" means today at midnight 00:00:00, one second after
    #         23:59:59 yesterday
    # "yesterday" means the day before today at midnight 00:00:00
    # "tomorrow" means the day after today at midnight 00:00:00,
    #         one second after 23:59:59 today
    # "now" means this-very-instance (more or less)
    case dt.downcase
    when "today"                    # "Round off" today/now to midnight
      tmp = Time.now.to_s.split[0]  # (discard time part of date-time)
    when "yesterday"                # Again, "round off" to midnight...
      tmp = ( Time.now - SEC_IN_DAY ).to_s.split[0]
    when "tomorrow"                 # Again, "round off" to midnight...
      tmp = ( Time.now + SEC_IN_DAY ).to_s.split[0]
    when "now"                      # Use exactly "now"...
      tmp = Time.now.to_s
    else   # use the date-time actually given...
      tmp = dt
    end  # case
    Time.parse( tmp )
  end  # thisday

end  # class DateCalc
