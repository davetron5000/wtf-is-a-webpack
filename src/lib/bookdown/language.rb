require 'pathname'
module Bookdown
  class Language
    def initialize(filename)
      filename = Pathname(filename)
      @language = if filename.extname == ".js"
                    "javascript"
                  elsif filename.extname == ".html"
                    "html"
                  elsif filename.extname == ".css"
                    "css"
                  elsif filename.extname == ".json"
                    "json"
                  else
                    raise "Can't determine language for #{filename} (extension '#{filename.extname}')"
                  end
    end

    def to_s
      @language
    end
    alias :to_str :to_s
  end
end
