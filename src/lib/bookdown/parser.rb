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

    def initialize(work_dir: , dist_dir: )
      @work_dir = Pathname(work_dir)
      @dist = Pathname(dist_dir)
    end

    def parse(file)
      existing_multiline_directive = nil

      input = Pathname(file)
      output = @dist / input.basename
      File.open(output,"w") do |file|
        File.open(input) do |input|
          chdir @work_dir do
            input.readlines.each do |line|
              if existing_multiline_directive
                commands = existing_multiline_directive.append(line)
                command_executor.execute_all(commands,file)
                existing_multiline_directive = nil unless existing_multiline_directive.continue?
              elsif line =~ /^!DUMP_CONSOLE (.*)$/
                html = $1
                exec_and_print("phantomjs ../src/dump_console.js #{html}",file, show_command: false)
              elsif line =~ /^!SCREENSHOT (.*)$/
                html,screenshot = $1.split(/\s+/)
                mkdir_p @dist / "images"
                exec_and_print("phantomjs ../src/screenshot.js #{html} #{@dist}/images/#{screenshot}",file) do |command,result|
                  file.puts "![screenshot](images/#{screenshot})"
                end
              elsif sh_directive = Bookdown::Directives::Sh.recognize(line)
                commands = sh_directive.execute
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
      @command_executor ||= Bookdown::CommandExecutor.new
    end

    def language(filename)
      if filename =~ /\.js/
        "javascript"
      elsif filename =~ /\.html/
        "html"
      else
        raise "Can't determine language for #{filename}"
      end
    end

    def exec_and_print(command,io, show_command: true, show_stdout: true, &block)
      puts "Executing #{command}"
      stdout,stderr,status = Open3.capture3(command)
      puts stdout
      puts stderr
      if status.success?
        if block.nil?
          io.puts "```"
          io.puts "> #{command}" if show_command
          io.puts stdout if show_stdout
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
