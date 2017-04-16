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
              elsif do_and_screenshot_directive = Bookdown::Directives::DoAndScreenshot.recognize(line,@screenshots_dir)
                raise "already inside an DO_AND_SCREENSHOT" if existing_multiline_directive
                existing_multiline_directive = do_and_screenshot_directive
                commands = existing_multiline_directive.execute
                command_executor.execute_all(commands,file)
              elsif package_json_directive = Bookdown::Directives::PackageJson.recognize(line)
                raise "already inside an PACKAGE_JSON" if existing_multiline_directive
                existing_multiline_directive = package_json_directive
                commands = existing_multiline_directive.execute
                command_executor.execute_all(commands,file)
              elsif add_to_directive = Bookdown::Directives::CreateFile.recognize(line)
                raise "already inside an ADD_TO" if existing_multiline_directive
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

    def command_executor
      @command_executor ||= Bookdown::CommandExecutor.new(logger: @logger)
    end

    def exec_and_print(command,io, show_command: true, show_stdout: true, &block)
      @logger.info "Executing #{command}"
      stdout,stderr,status = Open3.capture3(command)
      @logger.debug stdout
      @logger.info stderr
      if status.success?
        if block.nil?
          io.puts "```"
          io.puts "> #{command}" if show_command
          io.puts stdout if show_stdout && stdout.strip != ""
          io.puts "```"
        else
          block.(command,stdout)
        end
      else
        raise status.inspect + "\n" + stdout + "\n" + stderr
      end
    end
  end
end
