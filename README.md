This code will pull your forum body, inline images, and attachments to your local computer. It requires the following gems in order to work

require 'rubygems'
[require 'httparty'](http://httparty.rubyforge.org/)
require 'FileUtils'
[require 'nokogiri'](http://nokogiri.org/)
[require 'crack'](https://github.com/jnunemaker/crack)
require 'uri'

Just set the the following in the code. 
user email and password
local directory 
Your Zendesk URL

In order to get nokogiri to work on the mac you need to have [GCC](https://github.com/kennethreitz/osx-gcc-installer/downloads) installed. 
