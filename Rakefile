require "pathname"
require "bookdown/builder"

desc "Clean out wip"
task :clean do
  FileUtils.rm_rf "work"
  FileUtils.rm_rf "parsed_markdown"
  wd = Pathname(FileUtils.pwd)
  while wd.to_s != "/"
    if File.exist?(wd / "package.json")
      fail "There is a package.json in #{wd} which will make Yarn totally not work because reasons"
    end
    wd = (wd / "..").expand_path
  end
end

task default: :build

desc "Build it all"
task :build do
  book = Bookdown::Book.new(
                src_dir: ".",
      static_images_dir: "images",
           markdown_dir: "markdown",
               work_dir: "work",
    parsed_markdown_dir: "parsed_markdown",
               site_dir: Pathname("../what-problem-does-it-solve.com/site").expand_path / "webpack",
                  title: "Webpack from Nothing",
               subtitle: "Minimizing Pain while Learning Why Things Work",
                 author: "David Bryant Copeland AKA @davetron5000"
  )

  logger = Logger.new(STDOUT)
  logger.level = ENV["DEBUG"] == "true" ? Logger::DEBUG : Logger::INFO
  builder = Bookdown::Builder.new(logger: logger)
  builder.build(book)
end
