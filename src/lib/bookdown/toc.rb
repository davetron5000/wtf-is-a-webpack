require "pathname"

module Bookdown
  class TOC
    include Enumerable
    def initialize(markdown_dir: )
      @markdown_dir = Pathname(markdown_dir).expand_path
      parse_chapters
    end

    def parse_chapters
      toc = JSON.parse(File.read(@markdown_dir / "toc.json"))["toc"]
      @chapters = toc.map { |chapter_hash|
        Chapter.new(hash: chapter_hash)
      }
      @chapters.each_with_index do |chapter,index|
        if index != 0
          chapter.previous_chapter = @chapters[index-1]
        end
        chapter.next_chapter = @chapters[index+1]
      end
    end
    def each(&block)
      @chapters.each(&block)
    end

    class Chapter
      attr_accessor :previous_chapter, :next_chapter

      def initialize(hash:)
        @hash = hash
      end

      def title
        @title ||= @hash["title"]
      end

      def basename
        @basename ||= "#{@hash["name"]}.md"
      end

      def url
        @url ||= @hash["name"] + ".html"
      end
    end
  end
end
