#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# how-big-is-smallest-bignum.rb
#
# Copyright © 2014-2017 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.1, 01/25/2015
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# -----

require_relative 'lib/ppstrnum'

def bsprogress( iter, lo, mid, hi )
  slo  = "l: #{lo.thousands} #{lo.class};"
  smpr = "m-1: #{(mid-1).thousands} #{(mid-1).class};"
  smid = "m: #{mid.thousands} #{mid.class};"
  shi  = "h: #{hi.thousands} #{hi.class}"
  puts "#{iter}:  #{slo} #{smpr} #{smid} #{shi}"
end  # bsprogress

def binary_search( report, lo = 1, hi = 2**128 )
  iter = 0
  while lo < hi
    iter += 1
    mid = ( hi - lo ).div( 2 ) + lo
    bsprogress( iter, lo, mid, hi ) if report && iter % report == 0
    return [ mid, iter ] if ( (mid-1).kind_of? Fixnum ) && ( mid.kind_of? Bignum )
    (mid-1).kind_of?( Bignum ) ? hi = mid : lo = mid
  end  # while
  # Loop termination is lo == hi, so getting here means we didn't find the edge:
  raise "%binary_search-F-failed, failed to find Fixnum/Bignum edge"
end  # binary_search

# This hangs around just in case we want to step through code...
# require 'pry'
# binding.pry

# A non-nil ARGV[0] gives us a "stride" to report progress
#   through the binary search (every 1 or every 10, etc.);
#   no argument (nil) means no report;
#   argument of 0 or less is reset to 1 --
begin
  report_every = [ 1, ARGV[0].to_i ].max if !ARGV[0].nil?
rescue StandardError
  report_every = nil
end

bign, iter = binary_search( report_every )
fixn = bign - 1

if !ARGV[0]
  puts "\nThe Bignum-to-Fixnum edge occurs at"
  puts "#{bign.class}: #{bign.thousands} ...or"
  puts "#{bign.numbernames}"
  puts "      ...and"
  puts "#{fixn.class}: #{fixn.thousands} ...or"
  puts "  #{fixn.numbernames}"
else
  puts "\nEdge: #{fixn.thousands} #{fixn.class} | #{bign.thousands} #{bign.class} (#{iter} iterations)"
end
