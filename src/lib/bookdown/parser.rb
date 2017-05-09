require 'pathname'
require 'open3'
require 'json'
require 'pathname'
require 'fileutils'

require_relative "directives"
require_relative "command_executor"

module Bookdown
  class Parser
    include FileUtils

    def initialize(work_dir: , screenshots_dir:, logger:)
      @work_dir        = Pathname(work_dir)
      @screenshots_dir = Pathname(screenshots_dir)
      @logger          = logger
    end

    def parse(input: , output:)
      existing_multiline_directive = nil

      File.open(output,"w") do |file|
        File.open(input) do |input|
          chdir @work_dir do
            input.readlines.each do |line|
              if existing_multiline_directive
                commands = existing_multiline_directive.append(line)
                command_executor.execute_all(commands,file)
                existing_multiline_directive = nil unless existing_multiline_directive.continue?
              elsif sh_directive = Bookdown::Directives::JsConsole.recognize(line)
                commands = sh_directive.execute
                command_executor.execute_all(commands,file)
              elsif screenshot_directive = Bookdown::Directives::Screenshot.recognize(line,@screenshots_dir)
                commands = screenshot_directive.execute
                command_executor.execute_all(commands,file)
              elsif sh_directive = Bookdown::Directives::Sh.recognize(line)
                commands = sh_directive.execute
                command_executor.execute_all(commands,file)
              elsif edit_directive = Bookdown::Directives::EditFile.recognize(line)
                existing_multiline_directive = edit_directive
                commands = existing_multiline_directive.execute
                command_executor.execute_all(commands,file)
              elsif do_and_screenshot_directive = Bookdown::Directives::DoAndScreenshot.recognize(line,@screenshots_dir)
                existing_multiline_directive = do_and_screenshot_directive
                commands = existing_multiline_directive.execute
                command_executor.execute_all(commands,file)
              elsif do_and_js_console_directive = Bookdown::Directives::DoAndJsConsole.recognize(line)
                existing_multiline_directive = do_and_js_console_directive
                commands = existing_multiline_directive.execute
                command_executor.execute_all(commands,file)
              elsif package_json_directive = Bookdown::Directives::PackageJson.recognize(line)
                existing_multiline_directive = package_json_directive
                commands = existing_multiline_directive.execute
                command_executor.execute_all(commands,file)
              elsif add_to_directive = Bookdown::Directives::CreateFile.recognize(line)
                existing_multiline_directive = add_to_directive
                commands = existing_multiline_directive.execute
                command_executor.execute_all(commands,file)
              else
                file.puts line
              end
            end
          end
        end
      end
      output
    end

  private

    def command_executor
      @command_executor ||= Bookdown::CommandExecutor.new(logger: @logger)
    end
  end
end
