require 'open-uri'
require 'teabag/environment'

module Teabag
  class SageConsole

    def initialize(options = nil, files = [])
      @options = options || {}
      @suites = {}
      @files = []

      Teabag::Environment.load(@options)
      Rails.application.config.assets.debug = false if Teabag.configuration.driver == "phantomjs"

      start_server
    end

    def execute(options = {}, files = [])
      @options = @options.merge(options) if options.present?
      #resolve(files)
      failure_count = 0
      Teabag::Suite.all.each do |suite|
        next if @options[:suite].present? && suite.name != @options[:suite]
        suite.spec_files.each do |spec|
          #execute the runner for this script
         STDOUT.print "Teabag running #{suite.name} suite at #{spec[:name]}\n" unless Teabag.configuration.suppress_log
          failure_count += run_spec(suite, spec)
        end
      end
      failure_count > 0
    rescue Teabag::Failure
      true
    rescue Teabag::RunnerException
      true
    end

    def run_spec(suite, spec_file)
      url = url(suite, spec_file)
      url += url.include?("?") ? "&" : "?"
      url += "reporter=Console"
      driver.run_specs(suite, url)
    end

    protected


    def start_server
      @server = Teabag::Server.new
      @server.start
    end


    def driver
      @driver ||= Teabag::Drivers.const_get("#{Teabag.configuration.driver.to_s.camelize}Driver").new
    end

    def filter(suite,spec_file)
      parts = []
      parts << "grep=#{URI::encode(@options[:filter])}" if @options[:filter].present?
      #(@suites[suite] || @files).each { |file| parts << "file[]=#{URI::encode(file)}" }
      parts << "file[]=#{URI::encode(spec_file[:path])}"
      "?#{parts.join('&')}" if parts.present?
    end

    def url(suite,spec_file)
      ["#{@server.url}#{Teabag.configuration.mount_at}", suite.name, filter(suite,spec_file)].compact.join("/")
    end
  end
end
