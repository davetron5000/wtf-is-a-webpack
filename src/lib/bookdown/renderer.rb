require "redcarpet"
require "erb"

module Bookdown
  class Renderer
    def initialize
      @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(with_toc_data: true),
                                          tables: true,
                                          no_intra_emphasis: true,
                                          fenced_code_blocks: true,
                                          autolink: true,
                                          disable_indented_code_blocks: true,
                                          strikethrough: true,
                                          superscript: true,
                                          highlight: true)
    end

    # Args are used by scope of ERB rendering
    def render(chapter:,
               template:,
               toc:,
               parsed_markdown_file:,
               html_file:)
      show_full_header = chapter.previous_chapter.nil?
      erb_renderer = ERB.new(File.read(template))
      File.open(html_file,"w") do |file|
        html = @markdown.render(File.read(parsed_markdown_file))
        file.puts(erb_renderer.result(binding))
      end
    end
  end
end
