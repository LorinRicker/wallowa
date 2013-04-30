#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# googlesearch.rb
# From Gregory Brown's 'Ruby Best Practices', Appendix B, p. 276
#
# Copyright © 2012 Lorin Ricker <Lorin@RickerNet.us>
# Version 0.3, 04/14/2012
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require 'json'
require 'open-uri'
require 'cgi'
require 'pp'

module GSearch
  extend self

  API_BASE_URI = "http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q="

  def show_results( query )
    results = response_data( query )
    results["responseData"]["results"].each do | match |
      puts CGI.unescapeHTML( match["titleNoFormatting"] ) +
           ":\n  " + match["url"]
    end
  end  # show_results

  def response_data( query )
    data = open( API_BASE_URI + URI.escape( query ),
                 "Referer" => "http://TheRockjack.com" ).read
    JSON.parse( data )
  end  # response_data

end  # module GSearch

# Command-line invocation:
if __FILE__ == $0
  $*.each { |s| puts "\n\"#{s}\"\n"; GSearch.show_results( s ) }
end
