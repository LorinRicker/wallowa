#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# xemails.rb
#
# Copyright © 2017 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# Extract email address(es) from StdIn (standard input)
#   Extended/variation from xurls.rb,
#   As suggested by Text Processing With Ruby, by Rob Miller, p.24
#   (Pragmatic Bookshelf, 2015, ISBN 13-978-1-68050-070-7)

$stdin.each_line do | line |
  emails = line.scan( %r{\b\S+@\S+\b} )
  emails.each { | email | puts email }
end

exit true
