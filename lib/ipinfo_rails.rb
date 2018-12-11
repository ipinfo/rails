require 'rack'
require 'ipinfo'

class IPinfoMiddleware
  def initialize(app, cache_options = {})
    @app = app

    token = cache_options.fetch(:token, nil)
    @ipinfo = IPinfo::create(@token, cache_options)
    @is_bot = cache_options.fetch(:is_bot, nil)
  end

  def call(env)
    request = Rack::Request.new(env)

    if !@is_bot.nil?
      bot = @is_bot.call(request)
      puts "is bot custom"
      puts bot
    else
      bot = default_is_bot(request)
      puts "is bot default"
      puts bot
    end

    unless bot
      ip = request.ip
      env["ipinfo"] = @ipinfo.details(ip)
    end

    @app.call(env)
  end

  private
    def default_is_bot(request)
      user_agent = request.user_agent.downcase
      user_agent.include?("bot") || user_agent.include?("intel")#("spider")
    end
end
