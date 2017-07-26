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
    def initialize(logger: nil)
      @logger = logger || Logger.new(STDOUT)
      @file_utils = if @logger.level == Logger::DEBUG
                      FileUtils::Verbose
                    else
                      FileUtils
                    end
    end

    class RenderableChapter < SimpleDelegator
      attr_reader :unparsed_markdown_file, :parsed_markdown_file

      def initialize(chapter,markdown_dir,parsed_markdown_dir)
        super(chapter)
        @unparsed_markdown_file = markdown_dir / self.basename
        @parsed_markdown_file   = parsed_markdown_dir / @unparsed_markdown_file.basename
      end

      def updated_content?
        return true unless File.exist?(parsed_markdown_file)
        File::Stat.new(unparsed_markdown_file).mtime > File::Stat.new(parsed_markdown_file).mtime
      rescue Errno::ENOENT
        true
      end
    end

    def build(book)
      clear_working_dirs(book)

      force_reparse = false
      toc = Bookdown::TOC.new(markdown_dir: book.markdown_dir)
      toc.each do |chapter|
        renderable_chapter = RenderableChapter.new(chapter,book.markdown_dir,book.parsed_markdown_dir)
        result = parse_chapter(book,renderable_chapter, force_reparse: force_reparse)
        if result && !force_reparse
          @logger.info "Chapter #{renderable_chapter.name} was re-parsed, forcing re-rendering and subsequent chapter reparsing"
          force_reparse = true
        end
        result = render_chapter(book,renderable_chapter,toc)
      end

      process_css(book)
      copy_images(book)
      copy_js(book)
    end

  private

    def clear_working_dirs(book)
      [
        :work_dir,
        :parsed_markdown_dir,
        :images_dir,
        :site_dir,
      ].each do |config_option|
    #    rm_rf book.send(config_option), verbose: @logger.level == Logger::DEBUG
        @file_utils.mkdir_p book.send(config_option)
      end
    end

    def updated?(input_files, output)
      template,markdown = *input_files
    File::Stat.new(template).mtime > File::Stat.new(output).mtime ||
        File::Stat.new(markdown).mtime > File::Stat.new(output).mtime
    rescue Errno::ENOENT
      true
    end

    def parse_chapter(book,chapter, force_reparse: false)
      chapter_saved_work = book.saved_work_dir / chapter.name
      if force_reparse || chapter.updated_content?
        @logger.info "Chapter #{chapter.title} parsing #{chapter.unparsed_markdown_file} into #{chapter.parsed_markdown_file}"

        do_parse(book,chapter,chapter_saved_work)
        true
      elsif Dir.exist?(chapter_saved_work)
        @logger.info "Chapter #{chapter.title} has not changed, restoring work dir"
        @file_utils.rm_rf book.work_dir
        @file_utils.cp_r chapter_saved_work / "work", book.work_dir
        false
      else
        @logger.info "#{chapter.unparsed_markdown_file} has not changed, but no saved work dir, so re-parsing into #{chapter.parsed_markdown_file}"
        do_parse(book,chapter,chapter_saved_work)
        true
      end
    end

    def do_parse(book,chapter,chapter_saved_work)
      parser = Bookdown::Parser.new(work_dir: book.work_dir, screenshots_dir: book.images_dir, logger: @logger)
      parser.parse(input: chapter.unparsed_markdown_file,
                   output: chapter.parsed_markdown_file)
      @file_utils.rm_rf chapter_saved_work
      @file_utils.mkdir_p chapter_saved_work
      @file_utils.cp_r book.work_dir, chapter_saved_work
    end

    def render_chapter(book,chapter,toc)
      template = book.html_dir / "chapter.html"
      html_file = book.site_dir / chapter.url
      if updated?([template,chapter.parsed_markdown_file], html_file)
        @logger.info "Chapter #{chapter.title} rendering #{chapter.parsed_markdown_file}"

        renderer = Bookdown::Renderer.new
        renderer.render(chapter: chapter,
                        toc: toc,
                        template: template,
                        parsed_markdown_file: chapter.parsed_markdown_file,
                        html_file: html_file)
      else
        @logger.info "Chapter #{chapter.title}'s HTML is up to date"
      end
    end

    def process_css(book)
      sass_file = book.scss_dir / "styles.scss"
      css_file  = book.site_dir / "styles.css"
      update = File::Stat.new(sass_file).mtime > File::Stat.new(css_file).mtime rescue true
      if update
        sass_command = Bookdown::Directives::Commands::Sh.new(command: "sass --update #{sass_file}:#{css_file}")
        sass_command.execute(StringIO.new,@logger)
      else
        @logger.info "#{css_file} is up to date, not re-running SASS"
      end
    end

    def copy_images(book)
      @file_utils.mkdir_p book.images_dir
      Dir[book.static_images_dir / "*" ].each do |file|
        next if [".",".."].include?(file)
        @logger.info "Copying #{file} to #{book.images_dir}"
        @file_utils.cp file,book.images_dir
      end
      if book.images_dir.exist?
        @file_utils.cp_r book.images_dir, book.site_dir
      end
    end

    def copy_js(book)
      @file_utils.mkdir_p book.js_dir
      Dir[book.js_src_dir / "*.js" ].each do |file|
        next if [".",".."].include?(file)
        @logger.info "Copying #{file} to #{book.js_dir}"
        @file_utils.cp file,book.js_dir
      end
    end

  end
end
