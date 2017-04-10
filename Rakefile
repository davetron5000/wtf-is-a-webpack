require "fileutils"
require "pathname"
require "logger"

require_relative "src/lib/bookdown/parser"
require_relative "src/lib/bookdown/renderer"
require_relative "src/lib/bookdown/toc"

include FileUtils

config = {

             scss_dir: Pathname("src") / "scss",
             html_dir: Pathname("src") / "html",
         markdown_dir: Pathname("markdown").expand_path,
             work_dir: Pathname("work").expand_path,
  parsed_markdown_dir: Pathname("parsed_markdown").expand_path,
      screenshots_dir: Pathname("parsed_markdown").expand_path / "images",
             site_dir: Pathname("site"),

}

logger = Logger.new(STDOUT)
sass_command = Bookdown::Directives::Commands::Sh.new(command: "sass --update #{config[:scss_dir] / 'styles.scss' }:#{config[:site_dir]}/styles.css")

task :dirs do
  [
    :work_dir,
    :parsed_markdown_dir,
    :screenshots_dir,
    :site_dir,
  ].each do |config_option|
    rm_rf config[config_option], verbose: logger.level == Logger::DEBUG
    mkdir config[config_option], verbose: logger.level == Logger::DEBUG
  end
end

desc "Build it all"
task :default => [ :dirs ] do

  parser   = Bookdown::Parser.new(work_dir: config[:work_dir], screenshots_dir: config[:screenshots_dir], logger: logger)
  renderer = Bookdown::Renderer.new
  toc      = Bookdown::TOC.new(markdown_dir: config[:markdown_dir])

  toc.map { |chapter|

    [
      chapter,
      chapter.input_file(config[:markdown_dir]),
      Pathname("parsed_markdown") / chapter.input_file(config[:markdown_dir]).basename
    ]

  }.each do |chapter,unparsed_markdown_file,parsed_markdown_file|
    logger.info "Chapter #{chapter.title} parsing #{unparsed_markdown_file} into #{parsed_markdown_file}"

    parser.parse(input: unparsed_markdown_file,
                output: parsed_markdown_file)

    logger.info "Chapter #{chapter.title} rendering #{parsed_markdown_file} into #{parsed_markdown_file}"

    renderer.render(chapter: chapter,
                   template: config[:html_dir] / "chapter.html",
       parsed_markdown_file: parsed_markdown_file,
                  html_file: chapter.output_file(config[:site_dir]))
  end


  sass_command.execute(StringIO.new,logger)
  if config[:screenshots_dir].exist?
    cp_r config[:screenshots_dir], config[:site_dir], verbose: logger.level == Logger::DEBUG
  end
end
