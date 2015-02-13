#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# StringUpdater.rb
#
# Copyright © 2015 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.0, 02/13/2015
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# Ruby Version Dependency: uses Ruby v2.x keyword arguments syntax

# -----

class String

  # Check the input string for a canonical 'Copyright © XXXX[-YYYY]' notice,
  # and if found, check that it is current, fix it if its stale.
  # Use:  textline.updateCopyright( [updtoyear: '2014'] [, verbose: true] )
  def updateCopyright( updtoyear: nil, verbose: false )
    line = self.to_s
    unless updtoyear
      require 'date'
      updtoyear = DateTime.now.year.to_s
    end
    decades = '19|20|21'
    copypat = /Copyright( ©)? (((#{decades})\d\d)(-((#{decades})\d\d)?)?)\s/
    # Interesting match groups in this cpat regexp:
    #   #3: always the first/beginning year XXXX
    #   #5: if present, the dash-range and year YYYY
    #   #6: if present, the last/ending year YYYY
    matched = copypat.match( line )
    return line unless matched      # no match?  done... return unaltered line
    if matched[6]
      if matched[6] >= updtoyear    # current? or also accept future date...
        $stderr.puts "%upd©-current: #{line}" if verbose
        return line
      end
    end
    #       Copyright © XXXX         -YYYY
    line = "Copyright © #{matched[3]}-#{updtoyear} "
    line = matched.pre_match + line + matched.post_match
    $stderr.puts "%upd@-updated: #{line}" if verbose
    return line
  end  # updateCopyright

end  # class
