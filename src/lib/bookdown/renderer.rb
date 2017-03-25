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

    def render(markdown_filename,template,output_filename)
      erb_renderer = ERB.new(File.read(template))
      File.open(output_filename,"w") do |file|
        html = @markdown.render(File.read(markdown_filename))
        file.puts(erb_renderer.result(binding))
      end
    end
  end
end
