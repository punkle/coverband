# frozen_string_literal: true

require 'logger'
require 'json'
require 'redis'

require 'coverband/version'
require 'coverband/at_exit'
require 'coverband/configuration'
require 'coverband/utils/file_path_helper'
require 'coverband/adapters/base'
require 'coverband/adapters/redis_store'
require 'coverband/adapters/file_store'
require 'coverband/utils/s3_report'
require 'coverband/utils/html_formatter'
require 'coverband/utils/result'
require 'coverband/utils/file_list'
require 'coverband/utils/gem_list'
require 'coverband/utils/source_file'
require 'coverband/utils/file_groups'
require 'coverband/utils/lines_classifier'
require 'coverband/utils/railtie' if defined? ::Rails::Railtie
require 'coverband/collectors/coverage'
require 'coverband/reporters/base'
require 'coverband/reporters/html_report'
require 'coverband/reporters/console_report'
require 'coverband/integrations/background'
require 'coverband/integrations/rack_server_check'
require 'coverband/reporters/web'
require 'coverband/integrations/middleware'
require 'coverband/integrations/background'
require 'coverband/integrations/resque' if defined? Resque

module Coverband
  CONFIG_FILE = './config/coverband.rb'

  class << self
    attr_accessor :configuration_data
  end

  def self.configure(file = nil)
    configuration_file = file || ENV.fetch('COVERBAND_CONFIG', CONFIG_FILE)
    configuration
    if block_given?
      yield(configuration)
    elsif File.exist?(configuration_file)
      load configuration_file
    else
      configuration.logger&.debug('using default configuration')
    end
  end

  def self.report_coverage(force_report = false)
    Coverband::Collectors::Coverage.instance.report_coverage(force_report)
  end

  def self.configuration
    self.configuration_data ||= Configuration.new
  end

  def self.start
    Coverband::Collectors::Coverage.instance
    AtExit.register
    Background.start if configuration.background_reporting_enabled && !RackServerCheck.running?
  end

  unless ENV['COVERBAND_DISABLE_AUTO_START']
    # Coverband should be setup as early as possible
    # to capture usage of things loaded by initializers or other Rails engines
    configure
    start
  end
end
