#encoding: utf-8
require 'sinatra'
require 'rss'
require './url'
require './feed'

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
    truncate(5)
end

def feed_nico(tag)
  base = 'www.nicovideo.jp'
  directories = ['tag', tag]
  queries = [{'key' => 'rss', 'value' => '2.0'}]
  url = URL.new(base, directories, queries)
  feed = Feed.new(url).regex([
      {:find => /<p class="nico-thumbnail"><img alt=".*\n/, 
        :replace => ''},
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
  # p url.host + url.path
  feed = Feed.new(url).truncate(5)
end

get '/new_movie' do
  feed_hatena1 = feed_hatena(params['tag1'])
  if params['tag2']
    feed_hatena2 = feed_hatena(params['tag2'])
    # feed_vimeo = feed_vimeo(params['tag2'])
  end
  feed_nico = feed_nico(params['tag1'])
  if params['tag2']
    feed = feed_hatena1.append(
      # feed_hatena2, feed_nico, feed_vimeo).
      feed_hatena2, feed_nico).
      unique
  else
    feed = feed_hatena1.append(feed_nico).unique
  end
  content_type = 'text/xml; charset=utf-8'
  feed.to_s
end