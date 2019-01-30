Gem::Specification.new do |s|
  s.name        = 'ipinfo-rails'
  s.version     = '0.1.1'
  s.date        = '2018-12-10'
  s.summary     = "The official Rails gem for IPinfo. IPinfo prides itself on being the most reliable, accurate, and in-depth source of IP address data available anywhere. We process terabytes of data to produce our custom IP geolocation, company, carrier and IP type data sets. You can visit our developer docs at https://ipinfo.io/developers."
  s.description = "The official Rails gem for IPinfo. IPinfo prides itself on being the most reliable, accurate, and in-depth source of IP address data available anywhere. We process terabytes of data to produce our custom IP geolocation, company, carrier and IP type data sets. You can visit our developer docs at https://ipinfo.io/developers."
  s.authors     = ["James Timmins"]
  s.email       = 'jameshtimmins@gmail.com'
  s.files       = ["lib/ipinfo-rails.rb"]
  s.homepage    = 'https://ipinfo.io'
  s.license     = 'Apache-2.0'

  s.add_runtime_dependency 'IPinfo', '~> 0.1.2'
  s.add_runtime_dependency 'rack', '~> 2.0'
end
