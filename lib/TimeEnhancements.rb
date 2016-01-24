#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# TimeEnhancements.rb
#
# Copyright © 2014-2016 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.0, 04/28/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# Adds a much-needed elapsed method to Time class

class Time

  SEC_IN_MIN = 60
  SEC_IN_HR  = SEC_IN_MIN * 60
  SEC_IN_DAY = SEC_IN_HR * 24

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

end  # class Time
