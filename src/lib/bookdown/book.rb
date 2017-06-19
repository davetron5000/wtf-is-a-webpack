require "pathname"

module Bookdown
  class Book
      attr_reader :scss_dir,
                  :html_dir,
                  :static_images_dir,
                  :markdown_dir,
                  :work_dir,
                  :parsed_markdown_dir,
                  :images_dir,
                  :site_dir

    def initialize(src_dir: ,
         static_images_dir: ,
              markdown_dir: ,
                  work_dir: ,
       parsed_markdown_dir: ,
                  site_dir: )

      src_dir              = Pathname(src_dir)
      @scss_dir            = src_dir / "scss"
      @html_dir            = src_dir / "html"
      @static_images_dir   = Pathname(static_images_dir).expand_path
      @markdown_dir        = Pathname(markdown_dir).expand_path
      @work_dir            = Pathname(work_dir).expand_path
      @parsed_markdown_dir = Pathname(parsed_markdown_dir).expand_path
      @images_dir          = @parsed_markdown_dir / "images"
      @site_dir            = Pathname(site_dir)

    end
  end
end
