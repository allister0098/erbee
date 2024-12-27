# frozen_string_literal: true

require "erbee/version"
require "erbee/configuration"
require "erbee/association_explorer"
require "erbee/model_info"
require "erbee/diagram_renderer"
require "erbee/cli"

module Erbee
  class Error < StandardError; end
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
