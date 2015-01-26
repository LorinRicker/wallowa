#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# ppstrnum.rb
#
# Copyright © 2011-2015 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.0, 01/25/2015
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# Note: A thousands method is defined for both Numeric and String
#       Classes, as it's feasible and expected to see invocations
#       of it for both 1234567890.thousands and "123456".thousands
#       instances (for both strings and numeric values).  Hence,
#       the Numeric.thousands is simply a wrapper, with a to_s
#       conversion, around String.thousands.

# -----

module Ppnumnum

  # These wrappers hand-off a Numeric (Integer, Bignum, etc. ) to
  # the same-named String method, handling the to_s conversion as a
  # convenience, thus avoiding calls like: 1234567890.to_s.thousands
  def thousands( sep = "," )
    self.to_s.thousands( sep )
  end  # thousands

  def numbernames( stanzasep = ',', setcase = :titlecase )
    self.to_s.numbernames( stanzasep, setcase )
  end  # numbernames

end  # module

# -----

module Ppstrnum

  # Separate groups of characters with a separator
  def groupsep( grp = 3, sep = ",", decpt = '.' )
    num = self.to_s.strip
    if num.include?(decpt)
      nums = num.split(decpt)
      nums.delete_if { |n| n == "" }
      num = nums[0]
    end
    thou = []
    while num != ""
      ln  = num.length < grp ? num.length : grp
      tpl = num[-ln,grp]
      num[-ln,grp] = ""
      thou << tpl
    end  # while
    thou = thou.reverse.join(sep)
    if nums
      nums[0] = thou
      thou = nums.join(decpt)
    end
    return thou
  end  # groupsep

  # Separate a string (usually digits) into thousands --
  # e.g. "23456789" => "23,456,789"
  # (See Note above, and Numeric.thousands below...)
  def thousands( sep = "," )
    self.groupsep( 3, sep )
  end  # thousands

# -----

  # This numbernames routine is based on Chris Pine's exercise/implementation
  # in his great introductory book "Learn to Program" (see his solution in
  # Appendix A, pp. 144-147), but improved for performance -- he uses a mutable
  # $illions array -- and extended generality, all the way up past one googol
  # and into the quadragintillions.
  #
  # These names of numbers corresponds to the "U.S., Canada and modern British
  # (Short Scale)" vocabulary -- the current implementation extends to the range
  # of 10^123 or "Quadragintillion", although the official vocabulary extends to
  # 10^3003 or "Millinillion."  As "one quadragintillion" exceeds "one googol" by
  # a magnitude of 10^23rd, this seems like "enough."
  # Authority: http://en.wikipedia.org/wiki/Names_of_large_numbers
  #
  # It's worth noting that this algorithm of ~122 lines of Ruby code generates,
  # for an equivalent number (one-to-one mapping) of discrete inputs, at least
  # two times (±) nine hundred ninety nine quadragintillion distinct and unique
  # output strings, the names of all of those numbers!
  #
  # Works for Integer, Fixnum and Bignum values, as well as for String
  # numeric representations:  "123456", "123,456,789" and "987_654_321"
  # (commas & underscores are stripped from the string representation).
  # Any decimal (fractional) value is truncated (stripped) and thus
  # ignored in resultant output.
  #
  # Provides parameter 'stanzasep' (default is a comma ',') which is a
  # character (or string) which separates the stanzas of the number word-
  # phrase; this separator can be a newline '\n' to display the number
  # word-phrase on multiple lines (one or more).  The newline '\n' separator
  # is mostly useful for com-line displays with echo -e and dcl.rb's invocation
  # -- for example:  $ echo -e $( numberlines 123123123123123123 )
  # Also provides parameter 'setcase' to control: "Title Cased Number
  # Strings" (the default), "Capitalized number strings", "UPPER CASED
  # NUMBER STRINGS" and "lower cased number strings" (which is how the
  # string representation is initially generated).
  def numbernames( stanzasep = ',', setcase = :titlecase )
    ## require_relative 'Diagnostics'
    ## code = Diagnostics::Code.new( colorize = :red )
    $ones  ||= %w{ one       two      three
                   four      five     six
                   seven     eight    nine }
    $tys   ||= %w{ ten       twenty   thirty
                   forty     fifty    sixty
                   seventy   eighty   ninety }
    $teens ||= %w{ eleven    twelve   thirteen
                   fourteen  fifteen  sixteen
                   seventeen eighteen nineteen }
    # Authority for number names:
    # http://en.wikipedia.org/wiki/Names_of_large_numbers
    $illions ||= [
                   [ 123, 'quadragint' ],
                   [ 120, 'noven'      ],        # 'trigint'
                   [ 117, 'octo'       ],
                   [ 114, 'septen'     ],
                   [ 111, 'ses'        ],
                   [ 108, 'quinqua'    ],
                   [ 105, 'quattuor'   ],
                   [ 102, 'tres'       ],
                   [ 100, 'googol'     ],
                   [  99, 'duo'        ],
                   [  96, 'un'         ],
                   [  93, ''           ],        # 'trigint'
                   [  90, 'novem'      ],        # 'vigint'
                   [  87, 'octo'       ],
                   [  84, 'septem'     ],
                   [  81, 'ses'        ],
                   [  78, 'quinqua'    ],
                   [  75, 'quatturo'   ],
                   [  72, 'tres'       ],
                   [  69, 'duo'        ],
                   [  66, 'un'         ],
                   [  63, ''           ],        # 'vigint'
                   [  60, 'noven'      ],        # 'dec'
                   [  57, 'octo'       ],
                   [  54, 'septen'     ],
                   [  51, 'se'         ],
                   [  48, 'quinqua'    ],
                   [  45, 'quattuor'   ],
                   [  42, 'tre'        ],
                   [  39, 'duo'        ],
                   [  36, 'un'         ],
                   [  33, ''           ],        # 'dec'
                   [  30, 'non'        ],
                   [  27, 'oct'        ],
                   [  24, 'sept'       ],
                   [  21, 'sext'       ],
                   [  18, 'quint'      ],
                   [  15, 'quadr'      ],
                   [  12, 'tr'         ],
                   [   9, 'b'          ],
                   [   6, 'm'          ],
                   [   3, 'thousand'   ],
                   [   2, 'hundred'    ]
                 ]
    # Convert any \-chars:
    sep = stanzasep
    #pp ["stanzasep",stanzasep,sep]
    # Discard any fractional part, remove any separators:
    nstr   = self.split('.')[0].gsub(',','').gsub('_','')
    number = nstr.to_i
    result = ''
    minus  = number < 0 ? 'minus ' : ''
    if number != 0
      #  left: current residue of original value to process
      # write: the current chunk in-process (writing out)
      left = number.abs
      $illions.each do | zillion |
        zname = zillion[1]
        zbase = zillion[0]
        zpwr  = 10 ** zbase
        write = left / zpwr          # how many zillions left?
        left  = left - write * zpwr  # residue...
        if write > 0
          ## code.trace( recursion: "#{write}.to_s.numbernames(#{stanzasep,setcase})" )
          prefix = write.to_s.numbernames( stanzasep, setcase )  # recurse
          # Aggregate prefix and common-suffixes:
          result = result + prefix
          zname = zname + 'trigint'  if (93..120).cover?(zbase) && zbase % 3 == 0
          zname = zname + 'vigint'   if (63.. 90).cover?(zbase)
          zname = zname + 'dec'      if (33.. 60).cover?(zbase)
          zname = zname + 'illion' + sep if (6..123).cover?(zbase) && zbase % 3 == 0
          result = result + ' ' + zname
          # Commas after "*illion"; special case, after "thousand" too:
          result = result + sep if zbase == 3
          # Don't form something like 'two billionfifty-one'
          result = result + ' ' if left > 0
        end
      end  # $illions.each
      # Decades:
      write = left / 10               # how many tens left?
      left  = left - write * 10       # residue...
      if write > 0
        if write == 1 && left > 0
          result = result + $teens[left-1]
          left   = 0  # nothing left to write
        else
          result = result + $tys[write-1]
        end
        # Hyphenate "sixty-four"
        result = result + '-' if left > 0
      end
      # Units:
      write  = left                    # how many ones left?
      left   = 0                       # no more residue...
      result = result + $ones[write-1] if write > 0
      # It's easier to check & remove a trailing-comma than it is to prevent it:
      result = result[0..-2] if result[-1] == ','
      result = minus + result
    else
      result = 'zero'
    end  # if number != 0
    case setcase.to_sym
      # default: :lo(wer)case, :downcase is how it's built...
    when :uppercase,:upcase
      # All UPCASE, like might be preferred for printing checks
      result = result.upcase
    when :capcase,:capitalize
      # Capitalize the first word of the phrase only
      result = result.capitalize
    when :titlecase
      # Capitalize all all words of the phrase
      capwords = []
      result.split.each { |w| capwords << w.capitalize }
      result = capwords.join(' ')
    end
    return result
  end  # numbernames

end  # module

# -----

class Numeric
  include Ppnumnum
end
class String
  include Ppstrnum
end
