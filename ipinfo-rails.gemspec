# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'ipinfo-rails/version'

Gem::Specification.new do |s|
    s.name = 'ipinfo-rails'
    s.version = IPinfoRails::VERSION
    s.required_ruby_version = '>= 2.5.0'
    s.date = '2018-12-10'
    s.summary = 'The official Rails gem for IPinfo. IPinfo prides itself on ' \
                'being the most reliable, accurate, and in-depth source of ' \
                'IP address data available anywhere. We process terabytes ' \
                'of data to produce our custom IP geolocation, company, ' \
                'carrier and IP type data sets. You can visit our developer ' \
                'docs at https://ipinfo.io/developers.'
    s.description = s.summary
    s.authors = ['James Timmins', 'Uman Shahzad']
    s.email = ['jameshtimmins@gmail.com', 'uman@mslm.io']
    s.homepage = 'https://ipinfo.io'
    s.license = 'Apache-2.0'

    s.add_runtime_dependency 'IPinfo', '~> 1.0.1'
    s.add_runtime_dependency 'rack', '~> 2.0'

    s.files = `git ls-files -z`.split("\x0").reject do |f|
        f.match(%r{^(test|spec|features)/})
    end
    s.require_paths = ['lib']
end
