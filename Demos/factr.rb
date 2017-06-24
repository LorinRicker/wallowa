#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# factr.rb -- recursive version
#
# Copyright (C) 2011-2012 Lorin Ricker <lorin@rickernet.us>
# Version: 0.3, 04/14/2012
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

def factr( n )
  if n <= 1
    1
  else
    n * factr( n - 1 )
  end
end  # factr

