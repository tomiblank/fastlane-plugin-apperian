module Fastlane
  module Helper
    class ApperianHelper
      # class methods that you define here become available in your action
      # as `Helper::ApperianHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the apperian plugin helper!")
      end
    end
  end
end
