# myexternalip.rb

# 1-liner:
# ruby -e 'require "net/http"; \
#     url = "http://myexternalip.com"; \
#     Net::HTTP.get_print(url, "/raw")'
#

require 'net/http'
url = 'http://myexternalip.com'
ip = Net::HTTP.get( 'http://myexternalip.com', '/raw' )

print ip
