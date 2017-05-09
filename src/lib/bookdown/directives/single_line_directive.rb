module Bookdown
  module Directives
    module SingleLineDirective

      def continue?
        false
      end

      def append(_line)
        []
      end
    end
  end
end
