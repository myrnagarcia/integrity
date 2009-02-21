require "webrat/rack"
require "sinatra/test"

Webrat.configure do |config|
  config.mode = :sinatra
end

# TODO: Weird, the env seems to overriden somewhere
Integrity::App.set(:environment  => :test,
                   :raise_errors => false,
                   :run          => false,
                   :reload       => false)

module Webrat
  class SinatraSession
    DEFAULT_DOMAIN = "integrity.example.org"

    def initialize(context = nil)
      super(context)
      @sinatra_test = Sinatra::TestHarness.new(Integrity::App)
    end

    %w(get head post put delete).each do |verb|
      class_eval <<-METHOD
        def #{verb}(path, data, headers = {})
          params = data.inject({}) do |data, (key,value)|
            data[key] = Rack::Utils.unescape(value)
            data
          end
          headers['HTTP_HOST'] = DEFAULT_DOMAIN
          @sinatra_test.#{verb}(path, params, headers)
        end
      METHOD
    end

    def response_body
      @sinatra_test.body
    end

    def response_code
      @sinatra_test.status
    end

    private

    def response
      @sinatra_test.response
    end

    def current_host
      URI.parse(current_url).host || DEFAULT_DOMAIN
    end

    def response_location_host
      URI.parse(response_location).host || DEFAULT_DOMAIN
    end
  end
end
