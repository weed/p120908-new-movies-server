require 'uri'

class URL
  def initialize(base, directories = nil, queries = nil)
    @base = base
    @directories = directories
    @queries = queries
  end
  
  def to_s
    @url = @base + path
  end
  
  def host
    @base.sub(/http(s?):\/\//,'') #'http(s)://'を取る
  end
  
  def path
    @path = ""
    
    if @directories
      @directories.each do |directory|
        @path += ('/' + directory)
      end
    end
    
    if @queries
      # @path += ('?' + @queries[0]['key'] + '=' + CGI.escapeHTML(@queries[0]['value'].to_s))
      @path += ('?' + @queries[0]['key'] + '=' + URI.encode(@queries[0]['value'].to_s))
      @queries.shift
      if @queries.size > 0
        @queries.each do |query|
          # @path += ('&' + query['key'] + '=' + CGI.escapeHTML(query['value'].to_s))
          @path += ('&' + query['key'] + '=' + URI.encode(query['value'].to_s))
        end
      end
    end
    
    @path
  end # def
end