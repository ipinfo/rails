# frozen_string_literal: true

require 'rack'
require 'ipinfo'
require 'ipinfo_lite'
require 'ipinfo_core'
require 'ipinfo_plus'
require 'ipinfo-rails/ip_selector/default_ip_selector'

def is_bot(request)
  if request.user_agent
    user_agent = request.user_agent.downcase
    user_agent.include?('bot') || user_agent.include?('spider')
  else
    false
  end
end

class IPinfoMiddleware
    def initialize(app, _args = [], **options )
        @app = app
        @token = options.fetch(:token, nil)
        @ipinfo = IPinfo.create(@token, options)
        @filter = options.fetch(:filter, nil)
        @ip_selector = options.fetch(:ip_selector, DefaultIPSelector)
    end

    def call(env)
        env['called'] = 'yes'
        request = Rack::Request.new(env)
        ip_selector = @ip_selector.new(request)
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
end

class IPinfoLiteMiddleware
  def initialize(app, _args = [], **options )
    @app = app
    @token = options.fetch(:token, nil)
    @ipinfo = IPinfoLite.create(@token, options)
    @filter = options.fetch(:filter, nil)
    @ip_selector = options.fetch(:ip_selector, DefaultIPSelector)
  end

  def call(env)
    env['called'] = 'yes'
    request = Rack::Request.new(env)
    ip_selector = @ip_selector.new(request)
    filtered = if @filter.nil?
                 is_bot(request)
               else
                 @filter.call(request)
               end

    if filtered
      env['ipinfo'] = nil
    else
      ip = ip_selector.get_ip
      env['ipinfo'] = @ipinfo.details(ip)
    end

    @app.call(env)
  end
end

class IPinfoCoreMiddleware
  def initialize(app, _args = [], **options)
    @app = app
    @token = options.fetch(:token, nil)
    @ipinfo = IPinfoCore.create(@token, options)
    @filter = options.fetch(:filter, nil)
    @ip_selector = options.fetch(:ip_selector, DefaultIPSelector)
  end

  def call(env)
    env['called'] = 'yes'
    request = Rack::Request.new(env)
    ip_selector = @ip_selector.new(request)
    filtered = if @filter.nil?
                 is_bot(request)
               else
                 @filter.call(request)
               end

    if filtered
      env['ipinfo'] = nil
    else
      ip = ip_selector.get_ip
      env['ipinfo'] = @ipinfo.details(ip)
    end

    @app.call(env)
  end
end

class IPinfoPlusMiddleware
  def initialize(app, _args = [], **options)
    @app = app
    @token = options.fetch(:token, nil)
    @ipinfo = IPinfoPlus.create(@token, options)
    @filter = options.fetch(:filter, nil)
    @ip_selector = options.fetch(:ip_selector, DefaultIPSelector)
  end

  def call(env)
    env['called'] = 'yes'
    request = Rack::Request.new(env)
    ip_selector = @ip_selector.new(request)
    filtered = if @filter.nil?
                 is_bot(request)
               else
                 @filter.call(request)
               end

    if filtered
      env['ipinfo'] = nil
    else
      ip = ip_selector.get_ip
      env['ipinfo'] = @ipinfo.details(ip)
    end

    @app.call(env)
  end
end

class IPinfoResproxyMiddleware
  def initialize(app, _args = [], **options)
    @app = app
    @token = options.fetch(:token, nil)
    @ipinfo = IPinfo.create(@token, options)
    @filter = options.fetch(:filter, nil)
    @ip_selector = options.fetch(:ip_selector, DefaultIPSelector)
  end

  def call(env)
    env['called'] = 'yes'
    request = Rack::Request.new(env)
    ip_selector = @ip_selector.new(request)
    filtered = if @filter.nil?
                 is_bot(request)
               else
                 @filter.call(request)
               end

    if filtered
      env['ipinfo_resproxy'] = nil
    else
      ip = ip_selector.get_ip
      env['ipinfo_resproxy'] = @ipinfo.resproxy(ip)
    end

    @app.call(env)
  end
end
