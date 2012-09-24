#encoding: utf-8
require 'sinatra'
require 'rss'
require './url'
require './feed'

configure :production do
	require 'newrelic_rpm'
end

def feed_hatena(tag)
  base = 'b.hatena.ne.jp'
  directories = ['search', 'tag']
  queries = [{'key' => 'q', 'value' => tag},
    {'key' => 'of', 'value' => 0},
    {'key' => 'mode', 'value' => 'rss'}]
  url = URL.new(base, directories, queries)
  feed = Feed.new(url).
    filter({'title' => ['動画', '映像'], 
      'link' => ['youtube', 'vimeo', 'nicovideo']}).
    truncate(3)
end

def feed_nico(tag)
  base = 'www.nicovideo.jp'
  directories = ['tag', tag]
  queries = [{'key' => 'rss', 'value' => '2.0'}]
  url = URL.new(base, directories, queries)
  feed = Feed.new(url).regex([
      {:find => /<p class="nico-thumbnail"><img alt=".+" src="(.+)" width="94" height="70" border="0"\/><\/p>/, 
      :replace => '"\1"'},
      {:find => /<p class="nico-description">/,
        :replace => ''},
      {:find => /<\/p>/,
        :replace => ''},
      {:find => /<p class="nico-info">.*\n/,
        :replace => ''}
      ]).
      truncate(5)
end

def feed_vimeo(tag)
  base = 'vimeo.com'
  directories = ['tag:' + tag, 'rss']
  url = URL.new(base, directories)
  feed = Feed.new(url).
    regex([
      {:find => /<p><a href="http\:\/\/vimeo\.com\/.+"><img src="(.+)" alt="" \/><\/a><\/p><p><p class="first">/, 
        :replace => '"\1"'},
      {:find => /<p>/,
        :replace => ''},
      {:find => /<\/p>/,
        :replace => ''},
      {:find => /<br>/,
        :replace => ''},
      {:find => /<strong>/,
        :replace => ''},
      {:find => /<\/strong>/,
        :replace => ''},
      {:find => /<a href="http\:\/\/vimeo.com\/.+">/,
        :replace => ''},
      {:find => /<\/a>/,
        :replace => ''}
    ]).
    truncate(3)
end

get '/new_movie' do
  t1 = Thread.new do
    feed_nico = feed_nico(params['tag1'])
    puts 'nico' if DEBUG_APP
  end 
  t2 = Thread.new do
    if params['tag2']
      feed_vimeo = feed_vimeo(params['tag2'])
      puts 'vimeo' if DEBUG_APP     
    end
  end
  # Main Thread
  feed_hatena1 = feed_hatena(params['tag1'])
  puts 'hatena1' if DEBUG_APP
  
  t1.join
  t2.join
  
  unless params['tag2']
    feed = feed_hatena1.append(feed_nico).unique
  else
    feed = feed_hatena1.append(
      feed_nico, feed_vimeo).
      unique
      puts 'append + unique' if DEBUG_APP
  end
  content_type = 'text/xml; charset=utf-8'
  feed.to_s
end

get '/test.html' do
end

get '/index' do
  erb :index
end