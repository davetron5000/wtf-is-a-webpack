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

    def directives
      {
        Bookdown::Directives::JsConsole       => [ :line ],
        Bookdown::Directives::Screenshot      => [ :line, :screenshots_dir ],
        Bookdown::Directives::Sh              => [ :line ],
        Bookdown::Directives::EditFile        => [ :line ],
        Bookdown::Directives::DoAndScreenshot => [ :line, :screenshots_dir ],
        Bookdown::Directives::DoAndJsConsole  => [ :line ],
        Bookdown::Directives::PackageJson     => [ :line ],
        Bookdown::Directives::CreateFile      => [ :line ],
      }
    end

    def parse(input: , output:)
      existing_directive = nil

      File.open(output,"w") do |file|
        File.open(input) do |input|
          chdir @work_dir do
            input.readlines.each do |line|
              if existing_directive
                commands = existing_directive.append(line)
                command_executor.execute_all(commands,file)
                unless existing_directive.continue?
                  existing_directive = nil
                end
              elsif directive = detect_directive(line)
                commands = directive.execute
                command_executor.execute_all(commands,file)
                if directive.continue?
                  existing_directive = directive
                end
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

    def detect_directive(line)
      directives.map { |directive_klass,args_template|
        args = args_template.zip([line,@screenshots_dir]).map { |_| _[1] }
        @logger.debug("Checking #{directive_klass} against #{args}")
        directive_klass.recognize(*args)
      }.compact.first
    end

    def command_executor
      @command_executor ||= Bookdown::CommandExecutor.new(logger: @logger)
    end
  end
end
