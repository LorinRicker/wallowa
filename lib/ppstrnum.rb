#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# ppstrnum.rb
#
# Copyright © 2011-2018 Lorin Ricker <Lorin@RickerNet.us>
# Version 2.2, 05/18/2018
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

  # The following wrappers hands-off a Numeric (Integer, Bignum, etc. ) to the
  # same-named String method, handling the to_s conversion as a convenience,
  # thus avoiding calls like: 1234567890.to_s.thousands --

  def groupsep( grp = 3, sep = ',', decpt = '.' )
    self.to_s.groupsep( sep )
  end  # groupsep

  def thousands( sep = ',' )
    self.to_s.thousands( sep )
  end  # thousands

  def numbernames( stanzasep = ',', setcase = :titlecase )
    self.to_s.numbernames( stanzasep, setcase )
  end  # numbernames

  def asc_numstack( sep = ",\n" )
    self.to_s.asc_numstack( sep )
  end  # asc_numstack

  def desc_numstack( sep = ",\n" )
    self.to_s.desc_numstack( sep )
  end  # desc_numstack

  def pp_numstack( options )
    self.to_s.pp_numstack( options )
  end  # pp_numstack

  def engineering_notation( precision = 3, verbose = false )
    self.to_s.engineering_notation( precision, verbose )
  end  # engineering_notation

  def scientific_notation( precision = 3, verbose = false )
    self.to_s.scientific_notation( precision, verbose )
  end  # scientific_notation

  def exponential_notation( fmt, precision = 3, verbose = false )
    self.to_s.exponential_notation( fmt, precision, verbose )
  end  # exponential_notation

end  # module

# -----

module Ppstrnum

  # Separate groups of characters with a separator.  In this regard, see:
  #   http://en.wikipedia.org/wiki/Decimal_mark for discussion of common
  # practices and conventions -- herein, the U.S. comma-separator and
  # decimal point style is coded as the default, but other international
  # separators and points can be specified parametrically.
  # See also http://en.wikipedia.org/wiki/Wikipedia:Manual_of_Style/
  #          Dates_and_numbers#Decimal_points
  def groupsep( grp = 3, sep = ',', decpt = '.' )
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
  # (See also Note above in module Ppnumnum...)
  def thousands( sep = ',' )
    self.groupsep( 3, sep )
  end  # thousands

  def asc_numstack( sep = ",\n" )
    self.numbernames
        .split( ',' ).each { |s| s.strip! }
        .reverse
  end  # asc_numstack

  def desc_numstack( sep = ",\n" )
    self.numbernames
        .split( ',' ).each { |s| s.strip! }
  end  # desc_numstack

  def pp_numstack( options )
    result = Array.new
    tmp  = ( options[:format] == 'desc' ) ?
             self.desc_numstack( options[:separator] ) :
             self.asc_numstack( options[:separator] )
    if options[:just] == 'right'  # right justification
      maxl = tmp.each.max { |a,b| a.length <=> b.length }.length  # longest string-component?
      maxl = options[:indent] if options[:indent] > maxl  # use the widest
      tmp.each { | el | result << ( ' ' * ( maxl - el.length + 2 ) ) + el }
    else  # left justification
      maxl = ( options[:indent] > 2 ) ? options[:indent] : 2
      tmp.each { | el | result << ( ( ' ' * maxl ) + el ) }
    end
    result.join( "#{options[:separator]}\n" )
  end  # pp_numstack

  # Parameters:
  #    fmt : either "sci" (default) or :sci or "eng" or :eng
  #          to select either scientific or engineering Scientific_notation.
  #    precision : a positive, non-zero integer, specifies the number of
  #          significant digits to display (practically up to 10 or 12 digits).
  #    verbose : false (default) or true, which dumps internal/intermediate
  #          values for debugging and verification.
  #
  # See Wikipedia: https://en.wikipedia.org/wiki/Engineering_notation
  # and Wikipedia: https://en.wikipedia.org/wiki/Scientific_notation
  # Engineering notation, NNN.nnnExxx, means that the power of ten or exponent
  # "xxx" is a multiple of three (3), and the significand "NNN" is one, two or
  # three digits, with a decimal "nnn" part which is precision-digits long.
  # This format transformation is best handled (mostly) as string-manipulation
  # based on the "thousands" (comma-separated) representation of the number to
  # format.
  # Scientific notation, N.nnnExxx, allows any power of ten or exponent "xxx",
  # and normalizes significand "N" to one three digits, with a decimal "nnn"
  # part which is precision-digits long.
  # TO-DO: handle and check/text numbers < 0 -- 0.123 and 0.000234 should
  #        produce -xxx (negative exponent)
  def exponential_notation( fmt = "sci", precision = 3, verbose = false )
    comma = ','
    decpt = '.'
    zero  = '0'
    number = self.to_i
    numstr = self.to_s
    negative = number < 0 ? '-' : ''
    case fmt.to_sym
    when :eng  # this trick ensures that the exponent "xxx"
               #   will always be a multiple-of-3
      significand = number.abs.to_s.groupsep( 3, comma, decpt ).split( comma )[0]
      siglen = significand.length
      expletter = "E"  # Display as N.nnnExxx, with an uppercase "E" (not "e")
    when :sci  # general exponent "xxx"
      significand = numstr[0]  # first digit
      siglen = 1
      expletter = "e"  # Display as N.nnnexxx, with a lowercase "e" (not "E")
    else
      STDERR.puts "%exponential_notation-e-badformat, bad format for fmt (parameter-1);"
      STDERR.puts "                                   use either 'eng' or 'sci'"
      return self
    end  # case fmt
    decimals = nil
    if numstr.include?(decpt)
      nums = numstr.split( decpt )
      restdigits = nums[0][siglen..-1]
      decimals = nums[1]           # any digits after the decimal point
    else
      restdigits = numstr[siglen..-1]
    end
    decimals = zero * precision if !decimals  # if no decimal places, add some zeros
    exponent = restdigits.length
    restdigits += decimals if restdigits.length < precision
    roundingdigit = precision - siglen - 1
    fraction = restdigits[0,roundingdigit]  # slice enough more digits to make precision...
    fraction = fraction.succ if restdigits[roundingdigit].to_i >= 5  # round up?
    if verbose
      puts "exponential_notation -- #{fmt.to_s}"
      puts "      self is: '#{self.class}'"
      puts "  significand: '#{significand}' (len: #{siglen})"
      puts "   restdigits: '#{restdigits}'"
      puts "  round-digit: '#{restdigits[roundingdigit]}' '#{roundingdigit}'" if roundingdigit > 0
      puts "     exponent: '#{exponent}'"
      puts "     fraction: '#{fraction}'"
      puts "    precision: '#{precision}'"
    end
    return sprintf( "%s%s.%s%1s%s", negative, significand, fraction, expletter, exponent )
  end  # exponential_notation

# -----

  # This numbernames routine is based on Chris Pine's exercise/implementation
  # in his great introductory book "Learn to Program" (see his solution in
  # Appendix A, pp. 144-147), but improved for performance -- he uses a mutable
  # $illions array -- and extended generality, all the way up past one googol
  # and into the quadragintillions.
  #
  # These names of numbers corresponds to the "U.S., Canada and modern British
  # (Short Scale)" vocabulary -- the current implementation extends to the range
  # of 10^303 or "Centillion", although the official vocabulary extends to
  # 10^3003 or "Millinillion."  As "one centillion" exceeds "one googol" by
  # a magnitude of 10^203rd, this seems like "enough."
  #
  # It's worth noting that this algorithm of ~217 lines of Ruby code generates,
  # for an equivalent number (one-to-one mapping) of discrete inputs, at least
  # two times (±) a centillion distinct and unique output strings, the names of
  # all of those numbers!
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
    # Authorities for number names:
    # http://en.wikipedia.org/wiki/Names_of_large_numbers
    # http://www.unc.edu/~rowlett/units/large.html
    # ...and most consistent up through 'centillion':
    # http://www.thealmightyguru/Pointless/BigNumbers.html
    $illions ||= [
                   [ 303, 'cent'       ],  # centillion
                   [ 300, 'novem'      ],
                   [ 297, 'octo'       ],
                   [ 294, 'septen'     ],
                   [ 291, 'se'         ],
                   [ 288, 'quin'       ],
                   [ 285, 'quattuor'   ],
                   [ 282, 'tre'        ],
                   [ 279, 'duo'        ],
                   [ 276, 'un'         ],
                   [ 273, ''           ],  # nonagintillion
                   [ 270, 'novem'      ],
                   [ 267, 'octo'       ],
                   [ 264, 'septen'     ],
                   [ 261, 'ses'        ],
                   [ 258, 'quin'       ],
                   [ 255, 'quattuor'   ],
                   [ 252, 'tre'        ],
                   [ 249, 'duo'        ],
                   [ 246, 'un'         ],
                   [ 243, ''           ],  # octogintillion
                   [ 240, 'novem'      ],
                   [ 237, 'octo'       ],
                   [ 234, 'septen'     ],
                   [ 231, 'se'         ],
                   [ 228, 'quin'       ],
                   [ 225, 'quattuor'   ],
                   [ 222, 'tre'        ],
                   [ 219, 'duo'        ],
                   [ 216, 'un'         ],
                   [ 213, ''           ],  # septuagintillion
                   [ 210, 'novem'      ],
                   [ 207, 'octo'       ],
                   [ 204, 'septen'     ],
                   [ 201, 'se'         ],
                   [ 198, 'quin'       ],
                   [ 195, 'quattuor'   ],
                   [ 192, 'tre'        ],
                   [ 189, 'duo'        ],
                   [ 186, 'un'         ],
                   [ 183, ''           ],  # sexagintillion
                   [ 180, 'novem'      ],
                   [ 177, 'octo'       ],
                   [ 174, 'septen'     ],
                   [ 171, 'ses'        ],
                   [ 168, 'quin'       ],
                   [ 165, 'quattuor'   ],
                   [ 162, 'tre'        ],
                   [ 159, 'duo'        ],
                   [ 156, 'un'         ],
                   [ 153, ''           ],  # quinquagintillion
                   [ 150, 'novem'      ],
                   [ 147, 'octo'       ],
                   [ 144, 'septen'     ],
                   [ 141, 'ses'        ],
                   [ 138, 'quin'       ],
                   [ 135, 'quattuor'   ],
                   [ 132, 'tre'        ],
                   [ 129, 'duo'        ],
                   [ 126, 'un'         ],
                   [ 123, ''           ],  # quadragintillion
                   [ 120, 'novem'      ],
                   [ 117, 'octo'       ],
                   [ 114, 'septen'     ],
                   [ 111, 'ses'        ],
                   [ 108, 'quin'       ],
                   [ 105, 'quattuor'   ],
                   [ 102, 'tre'        ],
                   [ 100, 'googol'     ],
                   [  99, 'duo'        ],
                   [  96, 'un'         ],
                   [  93, ''           ],  # trigintillion
                   [  90, 'novem'      ],
                   [  87, 'octo'       ],
                   [  84, 'septen'     ],
                   [  81, 'ses'        ],
                   [  78, 'quin'       ],
                   [  75, 'quatturo'   ],
                   [  72, 'tre'        ],
                   [  69, 'duo'        ],
                   [  66, 'un'         ],
                   [  63, ''           ],  # vigintillion
                   [  60, 'novem'      ],
                   [  57, 'octo'       ],
                   [  54, 'septen'     ],
                   [  51, 'se'         ],
                   [  48, 'quin'       ],
                   [  45, 'quattuor'   ],
                   [  42, 'tre'        ],
                   [  39, 'duo'        ],
                   [  36, 'un'         ],
                   [  33, ''           ],  # decillion
                   [  30, 'non'        ],
                   [  27, 'oct'        ],
                   [  24, 'sept'       ],
                   [  21, 'sext'       ],
                   [  18, 'quint'      ],
                   [  15, 'quadr'      ],
                   [  12, 'tr'         ],
                   [   9, 'b'          ],
                   [   6, 'm'          ],  # -illion
                   [   3, 'thousand'   ],
                   [   2, 'hundred'    ]
                 ].freeze
    maxExponent = $illions[0][0]
    # Convert any \-chars:
    sep = stanzasep
    #pp ["stanzasep",stanzasep,sep]
    # Discard any fractional part, remove any separators:
    nstr   = self.split('.')[0].gsub(',','').gsub('_','')
    number = nstr.to_i
    # Sanity-range check:
    if number > ( 10 ** maxExponent * 10 ** 3 )  # can do up to 999 centillion+
      $stderr.puts "%ppstrnum-e-NYI, unknown name for number #{self.thousands}"
      return "(unknown name for number)"
    end
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
          zname = zname + 'nonagint'     if ( 273..300 ).cover?(zbase)
          zname = zname + 'octogint'     if ( 243..270 ).cover?(zbase)
          zname = zname + 'septuagint'   if ( 213..240 ).cover?(zbase)
          zname = zname + 'sexagint'     if ( 183..210 ).cover?(zbase)
          zname = zname + 'quinquagint'  if ( 153..180 ).cover?(zbase)
          zname = zname + 'quadragint'   if ( 123..150 ).cover?(zbase)
          zname = zname + 'trigint'      if (  93..120 ).cover?(zbase) && zbase % 3 == 0
          zname = zname + 'vigint'       if (  63.. 90 ).cover?(zbase)
          zname = zname + 'dec'          if (  33.. 60 ).cover?(zbase)
          zname = zname + 'illion' + sep if (6..maxExponent).cover?(zbase) && zbase % 3 == 0
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
