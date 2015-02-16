#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# StringUpdater.rb
#
# Copyright © 2015 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.1, 02/16/2015
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
    centuries = '19|20|21'
    copypat = /(Copyright(\s+©)?|©)\s+((?<xxxx>(#{centuries})\d\d)  # 'Copyright © 1986'
                (-(?<yyyy>(#{centuries})\d\d)?)?)\s/x               #  '-2015'
    # Interesting match groups in this cpat regexp (using named match-groups):
    #   ?<xxxx>, #4: always the first/beginning year 'XXXX'
    #   ?<yyyy>, #7: if present, the last/ending year 'YYYY'
    matched = copypat.match( line )
    return line unless matched        # no match?  done... return unaltered line
    # Two cases: matched[:xxxx] == 'XXXX', and matched[:yyyy] == nil or == 'YYYY' --
    if matched[:xxxx]
      # Is either 'XXXX' or 'YYYY' current year? Also accept future date(s)...
      current = matched[:xxxx] >= updtoyear
      # Separate tests because match[:yyyy] can be nil...
      current = matched[:yyyy] >= updtoyear if matched[:yyyy]
      if current
        $stderr.puts "%upd©-current: #{line}" if verbose
        return line
      end
    end
    #       Copyright © XXXX         -YYYY
    line = "Copyright © #{matched[:xxxx]}-#{updtoyear} "
    line = matched.pre_match + line + matched.post_match
    $stderr.puts "%upd@-updated: #{line}" if verbose
    return line
  end  # updateCopyright

end  # class
