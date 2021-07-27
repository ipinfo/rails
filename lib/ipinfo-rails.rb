# frozen_string_literal: true

require 'rack'
require 'ipinfo'

class IPinfoMiddleware
    def initialize(app, cache_options = {})
        @app = app
        @token = cache_options.fetch(:token, nil) || ENV['IPINFO_TOKEN']
        @ipinfo = IPinfo.create(@token, cache_options)
        @filter = cache_options.fetch(:filter, nil)
    end

    def call(env)
        request = Rack::Request.new(env)
        filtered = @filter.nil? ? is_bot(request) : @filter.call(request)
        env['ipinfo'] = filtered ? nil : @ipinfo.details(request.env["HTTP_X_FORWARDED_FOR"] || request.ip)
        @app.call(env)
    end

    private

    def is_bot(request)
        user_agent = request.user_agent.downcase
        user_agent.include?('bot') || user_agent.include?('spider')
    end
end
