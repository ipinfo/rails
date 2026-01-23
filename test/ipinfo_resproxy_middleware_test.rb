# frozen_string_literal: true

require 'minitest/autorun'
require 'mocha/minitest'
require 'rack/mock'
require 'ostruct'
require 'ipinfo'
require 'ipinfo/errors'
require_relative '../lib/ipinfo-rails'


# Simple Rack app
class TestApp
    attr_reader :last_env

    def call(env)
        @last_env = env
        [200, { 'Content-Type' => 'text/plain' }, ['Hello from TestApp!']]
    end
end

class IPinfoResproxyMiddlewareTest < Minitest::Test
    def setup
        @app = TestApp.new
        @middleware = nil
        @mock_ipinfo_client = mock('IPinfoClient')
        IPinfo.stubs(:create).returns(@mock_ipinfo_client)

        @mock_resproxy = OpenStruct.new(
            ip: '175.107.211.204',
            last_seen: '2026-01-15',
            percent_days_seen: 100,
            service: 'test_service'
        )
    end

    # Custom IP Selector
    class CustomIPSelector
        def initialize(request)
            @request = request
        end

        def get_ip
            '9.10.11.12'
        end
    end

    def test_should_use_default_ip_selector_when_no_custom_selector_is_provided
        @mock_ipinfo_client.expects(:resproxy).with('175.107.211.204').returns(@mock_resproxy)

        @middleware = IPinfoResproxyMiddleware.new(@app, token: 'test_token')
        request = Rack::MockRequest.new(@middleware)

        # Simulate a request with REMOTE_ADDR
        env = { 'REMOTE_ADDR' => '175.107.211.204' }
        response = request.get('/', env)

        assert_equal 200, response.status
        assert_equal 'yes', @app.last_env['called']
        assert_equal '175.107.211.204', @app.last_env['ipinfo_resproxy'].ip
        assert_equal 'test_service', @app.last_env['ipinfo_resproxy'].service
    end

    def test_should_use_custom_ip_selector_when_provided
        @mock_ipinfo_client.expects(:resproxy).with('9.10.11.12')
          .returns(@mock_resproxy.dup.tap { |d| d.ip = '9.10.11.12' })

        @middleware = IPinfoResproxyMiddleware.new(@app,
                                          token: 'test_token',
                                          ip_selector: CustomIPSelector)
        request = Rack::MockRequest.new(@middleware)

        response = request.get('/', {})

        assert_equal 200, response.status
        assert_equal 'yes', @app.last_env['called']
        assert_equal '9.10.11.12', @app.last_env['ipinfo_resproxy'].ip
    end

    def test_middleware_skips_processing_if_filter_returns_true
        always_filter = ->(_request) { true }

        @middleware = IPinfoResproxyMiddleware.new(@app,
                                          token: 'test_token',
                                          filter: always_filter)
        request = Rack::MockRequest.new(@middleware)

        @mock_ipinfo_client.expects(:resproxy).never

        response = request.get('/', { 'REMOTE_ADDR' => '8.8.8.8' })

        assert_equal 200, response.status
        assert_equal 'yes', @app.last_env['called']
        assert_nil @app.last_env['ipinfo_resproxy'],
                   'ipinfo_resproxy should be nil when filtered'
    end

    def test_middleware_processes_if_filter_returns_false
        never_filter = ->(_request) { false }
        @mock_ipinfo_client.expects(:resproxy).with('175.107.211.204').returns(@mock_resproxy)

        @middleware = IPinfoResproxyMiddleware.new(@app,
                                          token: 'test_token',
                                          filter: never_filter)
        request = Rack::MockRequest.new(@middleware)

        response = request.get('/', { 'REMOTE_ADDR' => '175.107.211.204' })

        assert_equal 200, response.status
        assert_equal 'yes', @app.last_env['called']
        assert_equal '175.107.211.204', @app.last_env['ipinfo_resproxy'].ip
    end

    def test_middleware_filters_bots_by_default
        @mock_ipinfo_client.expects(:resproxy).never # Should not call if bot

        @middleware = IPinfoResproxyMiddleware.new(@app, token: 'test_token')
        request = Rack::MockRequest.new(@middleware)

        # Test with common bot user agents
        bot_env = { 'HTTP_USER_AGENT' => 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)' }
        response = request.get('/', bot_env)

        assert_equal 200, response.status
        assert_equal 'yes', @app.last_env['called']
        assert_nil @app.last_env['ipinfo_resproxy'],
                   'ipinfo_resproxy should be nil for bot user agent'

        spider_env = { 'HTTP_USER_AGENT' => 'Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)' }
        response = request.get('/', spider_env)

        assert_equal 200, response.status
        assert_equal 'yes', @app.last_env['called']
        assert_nil @app.last_env['ipinfo_resproxy'],
                   'ipinfo_resproxy should be nil for spider user agent'
    end

    def test_middleware_does_not_filter_non_bots_by_default
        @mock_ipinfo_client.expects(:resproxy).with('175.107.211.204').returns(@mock_resproxy)

        @middleware = IPinfoResproxyMiddleware.new(@app, token: 'test_token')
        request = Rack::MockRequest.new(@middleware)

        # Test with a regular user agent
        user_env = { 'REMOTE_ADDR' => '175.107.211.204', 'HTTP_USER_AGENT' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' }
        response = request.get('/', user_env)

        assert_equal 200, response.status
        assert_equal 'yes', @app.last_env['called']
        assert_equal '175.107.211.204', @app.last_env['ipinfo_resproxy'].ip
    end

    def test_middleware_handles_missing_user_agent
        @mock_ipinfo_client.expects(:resproxy).with('175.107.211.204').returns(@mock_resproxy)

        @middleware = IPinfoResproxyMiddleware.new(@app, token: 'test_token')
        request = Rack::MockRequest.new(@middleware)

        # Test with no user agent provided
        no_ua_env = { 'REMOTE_ADDR' => '175.107.211.204' }
        response = request.get('/', no_ua_env)

        assert_equal 200, response.status
        assert_equal 'yes', @app.last_env['called']
        assert_equal '175.107.211.204', @app.last_env['ipinfo_resproxy'].ip
    end

    def test_middleware_handles_ipinfo_api_errors
        @mock_ipinfo_client.expects(:resproxy).raises(StandardError,
                                                      'API rate limit exceeded')

        @middleware = IPinfoResproxyMiddleware.new(@app, token: 'test_token')
        request = Rack::MockRequest.new(@middleware)

        assert_raises StandardError do
            request.get('/', { 'REMOTE_ADDR' => '175.107.211.204' })
        end
    end

    def test_middleware_passes_through_empty_response
        # Empty response simulates IP not in resproxy database
        empty_response = OpenStruct.new({})
        @mock_ipinfo_client.expects(:resproxy).with('175.107.211.204').returns(empty_response)

        @middleware = IPinfoResproxyMiddleware.new(@app, token: 'test_token')
        request = Rack::MockRequest.new(@middleware)

        response = request.get('/', { 'REMOTE_ADDR' => '175.107.211.204' })

        assert_equal 200, response.status
        assert_equal 'yes', @app.last_env['called']
        assert_equal empty_response, @app.last_env['ipinfo_resproxy']
    end
end
