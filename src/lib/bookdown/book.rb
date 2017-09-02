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
                  :site_dir,
                  :saved_work_dir,
                  :js_dir,
                  :js_src_dir,
                  :title,
                  :subtitle,
                  :author

    def initialize(src_dir: ,
         static_images_dir: ,
              markdown_dir: ,
                  work_dir: ,
       parsed_markdown_dir: ,
                  site_dir: ,
                     title: ,
                  subtitle: ,
                    author: )

      src_dir              = Pathname(src_dir)
      @scss_dir            = src_dir / "scss"
      @js_src_dir          = src_dir / "js"
      @html_dir            = src_dir / "html"
      @static_images_dir   = Pathname(static_images_dir).expand_path
      @markdown_dir        = Pathname(markdown_dir).expand_path
      @work_dir            = Pathname(work_dir).expand_path / "work"
      @saved_work_dir      = Pathname(work_dir).expand_path / "saved-work"
      @parsed_markdown_dir = Pathname(parsed_markdown_dir).expand_path
      @images_dir          = @parsed_markdown_dir / "images"
      @site_dir            = Pathname(site_dir)
      @js_dir              = @site_dir / "js"
      @title               = title
      @subtitle            = subtitle
      @author              = author

    end
  end
end
