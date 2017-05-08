require "logger"
require "fileutils"
require "pathname"

require_relative "parser"
require_relative "renderer"
require_relative "toc"
require_relative "book"
require_relative "directives/commands/sh"

module Bookdown
  class Builder
    include FileUtils

    def initialize
      @logger = Logger.new(STDOUT)
    end

    class RenderableChapter < SimpleDelegator
      attr_reader :unparsed_markdown_file, :parsed_markdown_file

      def initialize(chapter,markdown_dir,parsed_markdown_dir)
        super(chapter)
        @unparsed_markdown_file = markdown_dir / self.basename
        @parsed_markdown_file   = parsed_markdown_dir / @unparsed_markdown_file.basename
      end
    end

    def build(book)
      clear_working_dirs(book)

      each_chapter_config(book) do |chapter|
        parse_chapter(book,chapter)
        render_chapter(book,chapter)
      end

      process_css(book)
      copy_images(book)
    end

  private

    def clear_working_dirs(book)
      [
        :work_dir,
        :parsed_markdown_dir,
        :images_dir,
        :site_dir,
      ].each do |config_option|
        rm_rf book.send(config_option), verbose: @logger.level == Logger::DEBUG
        mkdir book.send(config_option), verbose: @logger.level == Logger::DEBUG
      end
    end

    def each_chapter_config(book,&block)
      Bookdown::TOC.new(markdown_dir: book.markdown_dir).each do |chapter|
        block.(RenderableChapter.new(chapter,book.markdown_dir,book.parsed_markdown_dir))
      end
    end

    def parse_chapter(book,chapter)
      @logger.info "Chapter #{chapter.title} parsing #{chapter.unparsed_markdown_file} into #{chapter.parsed_markdown_file}"

      parser = Bookdown::Parser.new(work_dir: book.work_dir, screenshots_dir: book.images_dir, logger: @logger)
      parser.parse(input: chapter.unparsed_markdown_file,
                   output: chapter.parsed_markdown_file)
    end

    def render_chapter(book,chapter)
      @logger.info "Chapter #{chapter.title} rendering #{chapter.parsed_markdown_file}"

      renderer = Bookdown::Renderer.new
      renderer.render(chapter: chapter,
                      template: book.html_dir / "chapter.html",
                      parsed_markdown_file: chapter.parsed_markdown_file,
                      html_file: book.site_dir / chapter.url)
    end

    def process_css(book)
      sass_command = Bookdown::Directives::Commands::Sh.new(command: "sass --update #{book.scss_dir / 'styles.scss' }:#{book.site_dir}/styles.css")
      sass_command.execute(StringIO.new,@logger)
    end

    def copy_images(book)
      mkdir_p book.images_dir
      Dir[book.static_images_dir / "*" ].each do |file|
        next if [".",".."].include?(file)
        @logger.info "Copying #{file} to #{book.images_dir}"
        cp file,book.images_dir, verbose: @logger.level == Logger::DEBUG
      end
      if book.images_dir.exist?
        cp_r book.images_dir, book.site_dir, verbose: @logger.level == Logger::DEBUG
      end
    end

  end
end
