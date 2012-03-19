require 'rubygems'
require 'httparty'
require 'pp'
require 'FileUtils'
#require 'open-uri'
require 'nokogiri'
require 'crack'
require 'uri'

class Zenuser
  include HTTParty
  base_uri 'http://skipjack.zendesk.com'
  #headers 'content-type'  => 'application/xml'
  def initialize(u, p)
      @auth = {:username => u, :password => p}
    end
  def get_entries(count)
    options = {:basic_auth => @auth}
    #print options
    self.class.get('/api/v1/entries.xml?page=' + count.to_s, options)
  end
  def get_name(forum_id, rdir)
    options = {:basic_auth => @auth}
    response = self.class.get('/api/v1/forums/' + forum_id.to_s + '.xml', options)
    name = Crack::XML.parse(response.body)
    if name['forum']['category_id'] != nil
      cat = self.class.get('/api/v1/categories/' + name['forum']['category_id'].to_s  + '.xml', options)
      catName = Crack::XML.parse(cat.body)
      dir = rdir + "/" + catName['category']['name'] + "/"
      Dir.mkdir(dir) unless File.exists?(dir)
      forumName = catName['category']['name'] + "/" + forum_id.to_s + "-" + name['forum']['name'].to_s.gsub(/\s/,'-')
    else
      dir = rdir + "/No-Category"
      Dir.mkdir(dir) unless File.exists?(dir)
      forumName = 'No-Category' + "/" + forum_id.to_s + "-" + name['forum']['name'].to_s.gsub(/\s/,'-')
    end
    return forumName
  end
  def get_attach(file, rdir)
    dir = rdir +"/images/"
    options = {:basic_auth => @auth}
    Dir.mkdir(dir) unless File.exists?(dir)
    begin
        imgURL = self.class.base_uri + file
        response = self.class.get(imgURL, options)
        if response.code == 200
          writeOut = open(dir + file.split('=')[-1], "wb")
          writeOut << self.class.get(imgURL, options)
          writeOut.close
        else
          puts "failed download " + imgURL
          #File.delete(dir + file.split('=')[-1])
        end
      rescue
        #File.delete(dir + file.split('=')[-1])
        puts "failed download " + imgURL
      end
   end       
end

x = Zenuser.new( 'skip@meail.net', 'password')

rootDir = "/Users/skip/Documents/Zendesk/test-forum"
count = 1;
while x.get_entries(1) do 
  test = x.get_entries(count)
  testBody = Crack::XML.parse(test.body)
  testBody['entries'].each do |entry|
    dir = rootDir + "/" + x.get_name(entry['forum_id'], rootDir) + "/"
    Dir.mkdir(dir) unless File.exists?(dir)
    File.open(dir + entry['id'].to_s + "-" + entry['title'].gsub(/\s/,'-').gsub(/\//,'-') + ".html", 'w+') do |the_file|
      the_file.puts entry['body']
    end
    entry['attachments'].each do |attachment|
      forumAttach = URI(attachment['url']).path + "?" + URI(attachment['url']).query
      x.get_attach(forumAttach, rootDir)
    end
    ntest = Nokogiri::HTML(entry['body'])
    ntest.css('img').each do |img|
      if img['src'].split('/')[1] == 'attachments'
        x.get_attach(img['src'], rootDir)
      end
    end
  end
  count += 1
end