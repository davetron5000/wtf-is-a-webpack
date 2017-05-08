require 'open3'

module Bookdown
  class ShRunner
    def initialize(command:, expecting_success: ,logger: )
      @command           = command
      @expecting_success = expecting_success
      @logger            = logger
    end
    def run_command
      @logger.info "Executing '#{@command}'"
      stdout,stderr,status = Open3.capture3(@command)
      command_did_what_was_expected = if @expecting_success
                                        status.success?
                                      else
                                        !status.success?
                                      end
      unless command_did_what_was_expected
        raise status.inspect + "\n" + stdout + "\n" + stderr
      end

      [stdout,stderr]
    end
  end
end
