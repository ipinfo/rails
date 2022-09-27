# frozen_string_literal: true

require 'rack'
require 'ipinfo'
require 'ipinfo-rails/ip_selector/default_ip_selector'

class IPinfoMiddleware
    def initialize(app, options = {})
        @app = app
        @token = options.fetch(:token, nil)
        @ipinfo = IPinfo.create(@token, options)
        @filter = options.fetch(:filter, nil)
        @ip_selector = options.fetch(:ip_selector, nil)
    end

    def call(env)
        env['called'] = 'yes'
        request = Rack::Request.new(env)
        ip_selector = if @ip_selector.nil? 
                        DefaultIPSelector.new(request)
                      else
                        @ip_selector.new(request)
                      end

        filtered = if @filter.nil?
                       is_bot(request)
                   else
                       @filter.call(request)
                   end

        if filtered
            env['ipinfo'] = nil
        else
            ip = ip_selector.get_ip()
            env['ipinfo'] = @ipinfo.details(ip)
        end

        @app.call(env)
    end

    private

    def is_bot(request)
        if request.user_agent
            user_agent = request.user_agent.downcase
            user_agent.include?('bot') || user_agent.include?('spider')
        else
            false
        end
    end
end
