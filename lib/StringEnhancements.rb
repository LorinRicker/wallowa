#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# StringEnhancements.rb
#
# Copyright © 2011-2018 Lorin Ricker <Lorin@RickerNet.us>
# Version 3.2, 05/16/2018
#
# Refactored into:
#   StringCases, StringIsIn, StringLexicals, StringModes, and StringSpellings
#
#   StringGroupings was provisional, turned out to be duplicate
#   to code in lib/ppstrnum.rb (PrettyPrintStringNumbers)
#
# This file now is merely a single-point "require_relative" for
# each/all of the above, each of which can be used separately
# and selectively, of course.
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require_relative "ppstrnum"
require_relative "StringCases"
require_relative "StringIsIn"
require_relative "StringLexicals"
require_relative "StringModes"
require_relative "StringSpellings"
