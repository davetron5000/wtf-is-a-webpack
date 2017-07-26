require "csv"
require_relative "single_line_directive"

module Bookdown
  module Directives
    class Ad
      include SingleLineDirective

      def self.recognize(line)
        if line =~ /^!AD\s+(.*)$/
          h1, h2, link, link_text, image = CSV::parse_line($1, col_sep: ' ')
          self.new(h1,h2,link,link_text,image)
        else
          nil
        end
      end

      attr_reader :h1, :h2, :link, :link_text, :image
      def initialize(h1, h2, link, link_text, image=nil)
        @h1 = h1
        @h2 = h2
        @link = link
        @link_text = link_text
        @image = image
      end

      def execute
        image_tag = if @image
%{
  <a href="#{@link}">
    <img src="#{@image}" width="200"/>
  </a>}
                    else
                      nil
                    end
        [
          Commands::PutsToFileIO.new(%{
<aside class="ad">
  <div class="banner">Promotion</div>
  <h1>#{@h1}</h1>
  <h2>#{@h2}</h2>#{image_tag}
  <h3>
    <a href="#{@link}">
      #{@link_text}
    </a>
  </h3>
</aside>
}
                                    )
        ]
      end

    end
  end
end
