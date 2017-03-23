require "redcarpet"
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

    def render(markdown_filename,output_filename)
      File.open(output_filename,"w") do |file|
        file.puts(@markdown.render(File.read(markdown_filename)))
      end
    end
  end
end
