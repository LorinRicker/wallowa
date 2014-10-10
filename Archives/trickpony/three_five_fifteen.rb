# three_five_fifteen.rb -- Code test problem, Peter Olsen, The Gannett Company

# solution coded by Lorin Ricker, 06/12/2013

# Print the numbers from 1 to 100, but...
#  if the number is evenly divisible by 3, print "#{n} is divisible by three",
#  but if the number is evenly divisible by 5, print "#{n} is divisible by five",
#  but if the number is evenly divisible by 15, print "#{n} is divisible by fifteen"

(1..100).each do | n |
  if n % 15 == 0
    puts "#{n} is divisible by fifteen"
    next
  end
  if n % 5 == 0
    puts "#{n} is divisible by five"
    next
  end
  if n % 3 == 0
    puts "#{n} is divisible by three"
    next
  end
  puts n
end
