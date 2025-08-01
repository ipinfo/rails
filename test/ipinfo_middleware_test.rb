# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/mock'
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

class IPinfoMiddlewareTest < Minitest::Test
    def setup
        @app = TestApp.new
        @middleware = nil
        @mock_ipinfo_client = mock('IPinfoClient')
        IPinfo.stubs(:create).returns(@mock_ipinfo_client)

        @mock_details = OpenStruct.new(
            ip: '1.2.3.4',
            city: 'New York',
            country: 'US',
            hostname: 'example.com',
            org: 'Example Org'
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
        @mock_ipinfo_client.expects(:details).with('1.2.3.4').returns(@mock_details)

        @middleware = IPinfoMiddleware.new(@app, token: 'test_token')
        request = Rack::MockRequest.new(@middleware)

        # Simulate a request with REMOTE_ADDR
        env = { 'REMOTE_ADDR' => '1.2.3.4' }
        response = request.get('/', env)

        assert_equal 200, response.status
        assert_equal 'yes', @app.last_env['called']
        assert_equal '1.2.3.4', @app.last_env['ipinfo'].ip
        assert_equal 'New York', @app.last_env['ipinfo'].city
    end

    def test_should_use_custom_ip_selector_when_provided
        @mock_ipinfo_client.expects(:details).with('9.10.11.12')
          .returns(@mock_details.dup.tap { |d| d.ip = '9.10.11.12' })

        @middleware = IPinfoMiddleware.new(@app,
                                          token: 'test_token',
                                          ip_selector: CustomIPSelector)
        request = Rack::MockRequest.new(@middleware)

        response = request.get('/', {})

        assert_equal 200, response.status
        assert_equal 'yes', @app.last_env['called']
        assert_equal '9.10.11.12', @app.last_env['ipinfo'].ip
    end

    def test_middleware_skips_processing_if_filter_returns_true
        always_filter = ->(_request) { true }

        @middleware = IPinfoMiddleware.new(@app,
                                          token: 'test_token',
                                          filter: always_filter)
        request = Rack::MockRequest.new(@middleware)

        @mock_ipinfo_client.expects(:details).never

        response = request.get('/', { 'REMOTE_ADDR' => '8.8.8.8' })

        assert_equal 200, response.status
        assert_equal 'yes', @app.last_env['called']
        assert_nil @app.last_env['ipinfo'],
                   'ipinfo should be nil when filtered'
    end

    def test_middleware_processes_if_filter_returns_false
        never_filter = ->(_request) { false }
        @mock_ipinfo_client.expects(:details).with('1.2.3.4').returns(@mock_details)

        @middleware = IPinfoMiddleware.new(@app,
                                          token: 'test_token',
                                          filter: never_filter)
        request = Rack::MockRequest.new(@middleware)

        response = request.get('/', { 'REMOTE_ADDR' => '1.2.3.4' })

        assert_equal 200, response.status
        assert_equal 'yes', @app.last_env['called']
        assert_equal '1.2.3.4', @app.last_env['ipinfo'].ip
    end

    def test_middleware_filters_bots_by_default
        @mock_ipinfo_client.expects(:details).never # Should not call if bot

        @middleware = IPinfoMiddleware.new(@app, token: 'test_token')
        request = Rack::MockRequest.new(@middleware)

        # Test with common bot user agents
        bot_env = { 'HTTP_USER_AGENT' => 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)' }
        response = request.get('/', bot_env)

        assert_equal 200, response.status
        assert_equal 'yes', @app.last_env['called']
        assert_nil @app.last_env['ipinfo'],
                   'ipinfo should be nil for bot user agent'

        spider_env = { 'HTTP_USER_AGENT' => 'Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)' }
        response = request.get('/', spider_env)

        assert_equal 200, response.status
        assert_equal 'yes', @app.last_env['called']
        assert_nil @app.last_env['ipinfo'],
                   'ipinfo should be nil for spider user agent'
    end

    def test_middleware_does_not_filter_non_bots_by_default
        @mock_ipinfo_client.expects(:details).with('1.2.3.4').returns(@mock_details)

        @middleware = IPinfoMiddleware.new(@app, token: 'test_token')
        request = Rack::MockRequest.new(@middleware)

        # Test with a regular user agent
        user_env = { 'REMOTE_ADDR' => '1.2.3.4', 'HTTP_USER_AGENT' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' }
        response = request.get('/', user_env)

        assert_equal 200, response.status
        assert_equal 'yes', @app.last_env['called']
        assert_equal '1.2.3.4', @app.last_env['ipinfo'].ip
    end

    def test_middleware_handles_missing_user_agent
        @mock_ipinfo_client.expects(:details).with('1.2.3.4').returns(@mock_details)

        @middleware = IPinfoMiddleware.new(@app, token: 'test_token')
        request = Rack::MockRequest.new(@middleware)

        # Test with no user agent provided
        no_ua_env = { 'REMOTE_ADDR' => '1.2.3.4' }
        response = request.get('/', no_ua_env)

        assert_equal 200, response.status
        assert_equal 'yes', @app.last_env['called']
        assert_equal '1.2.3.4', @app.last_env['ipinfo'].ip
    end

    def test_middleware_handles_ipinfo_api_errors
        @mock_ipinfo_client.expects(:details).raises(StandardError,
                                                      'API rate limit exceeded')

        @middleware = IPinfoMiddleware.new(@app, token: 'test_token')
        request = Rack::MockRequest.new(@middleware)

        assert_raises StandardError do
            request.get('/', { 'REMOTE_ADDR' => '1.2.3.4' })
        end
    end
end
