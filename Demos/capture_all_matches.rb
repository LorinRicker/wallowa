#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# capture_all_matches.rb
#
# Copyright © 2015 Lorin Ricker <Lorin@RickerNet.us>
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# This sample code demonstrates three ways to capture *all* of the offsets
# [begin,end,length] data for *all* matches scanned in a source string.

# Of course, each/any of the below examples could be turned into a class method
# in String &/or Regexp -- one wonders why these are not part of the built-in
# classes/methods?...

# An example source string (any will do):
s = "The fox hides in the box full of sox eating lox."
#       4^                  25^   31^

# Use the literal pattern /f/ as an example --
# there are three "f"s in the sample source string;
# see indexes above...
p = /f/

# 1. Just report an array of the begin (start) position of each match:
mpos = []
m = i = 0
m = p.match( s, i ) { |k| j = k.begin(0); i = j + 1; mpos << j } while m
p mpos   # => [4, 25, 31]

# 2. Make an array containing elements [begin,end] of matched substrings:
mpos = []
m = i = 0
m = p.match( s, i ) { |k| j = k.offset(0); i = j[0] + 1; mpos << j } while m
p mpos   # => [[4, 5], [25, 26], [31, 32]]

# 3. Make an array containing elements [begin,end,length] of matched substrings:
mpos = []
m = i = 0
m = p.match( s, i ) { |k| j = k.offset(0); i = j[0] + 1;
                          j << j[1] - j[0]; mpos << j    } while m
p mpos   # => [[4, 5, 1], [25, 26, 1], [31, 32, 1]]
