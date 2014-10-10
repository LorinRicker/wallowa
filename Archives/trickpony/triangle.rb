# triangle.rb -- Code test problem, Peter Olsen, The Gannett Company

# solution coded by Lorin Ricker, 06/12/2013

#  1
#  2  3
#  4  5  6
#  7  8  9 10
# 11 12 13 14 15
# ...

# Given an integer N = number-of-lines-to-print on the program's command-line:
#    $ ruby triangle N
# print that number of lines of the above-triangle such that the output is
# 1..i (arbitrary upper limit), but with 1 (one value) printed on line one,
# 2 and 3 (two values) on the second line, and so on...

puts ">>> Integer value (number of lines to output) required..." if !ARGV[0]
nlines = ARGV[0].to_i
width = nlines >= 5 ? ( nlines >= 14 ? 3 : 2 ) : 1
cntr = 1

nlines.times do | line |
  (line+1).times do
    print "#{ sprintf( "%#{width}s", cntr ) } "
    cntr += 1
  end
  print "\n"
end
