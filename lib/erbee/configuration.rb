module Erbee
  class Configuration
    attr_accessor :depth, :output_path

    def initialize
      @depth = 2
      @output_path = "er_diagram.md"
    end
  end
end

