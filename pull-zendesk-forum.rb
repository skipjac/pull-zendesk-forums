require 'rubygems'
require 'httparty'
require 'pp'
require 'FileUtils'
require 'json'
require 'nokogiri'
require 'crack'
require 'uri'

login = ARGV[0]
password = ARGV[1]
zendeskURL = ARGV[2]
infile = ARGV[3]

class Zenuser
  include HTTParty
  headers 'content-type'  => 'application/json'
  def initialize(u, p, y)
      @auth = {:username => u, :password => p}
      self.class.base_uri 'https://' + y + '.zendesk.com'
    end
  def get_entries(count)
    options = {:basic_auth => @auth}
    self.class.get(count.to_s, options)
  end
  def get_name(forum_id, rdir)
    options = {:basic_auth => @auth}
    response = self.class.get('/api/v2/forums/' + forum_id.to_s + '.json', options)
    name = JSON.parse(response.body)
    if name['forum']['category_id'] != nil
      cat = self.class.get('/api/v2/categories/' + name['forum']['category_id'].to_s  + '.json', options)
      catName = JSON.parse(cat.body)
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
        end
      rescue
        puts "failed download " + imgURL
      end
   end       
end

x = Zenuser.new(login, password, zendeskURL)
rootDir = infile
count = '/api/v2/topics.json'
while count != nil do
  test = x.get_entries(count)
  testBody = JSON.parse(test.body)
  testBody['topics'].each do |topic|
    dir = rootDir + "/" + x.get_name(topic['forum_id'], rootDir) + "/"
    Dir.mkdir(dir) unless File.exists?(dir)
    File.open(dir + topic['id'].to_s + "-" + topic['title'].to_s.gsub(/\s/,'-').gsub(/\//,'-')[0,27] + ".html", 'w+') do |the_file|
      the_file.puts topic['body']
    end
    topic['attachments'].each do |attachment|
      forumAttach = URI(attachment['content_url']).path + "?" + URI(attachment['content_url']).query
      x.get_attach(forumAttach, rootDir)
    end
    ntest = Nokogiri::HTML(topic['body'])
    # ntest.css('img').each do |img|
    #   if img['src'].split('/')[1] == 'attachments'
    #     x.get_attach(img['src'], rootDir)
    #   end
    #end
  end
  count = testBody['next_page']
end