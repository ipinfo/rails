Gem::Specification.new do |s|
  s.name        = 'ipinfo_rails'
  s.version     = '0.1.0'
  s.date        = '2018-12-10'
  s.summary     = "The official Rails middleware for IPinfo."
  s.description = "The official Rails middleware for IPinfo."
  s.authors     = ["James Timmins"]
  s.email       = 'jameshtimmins@gmail.com'
  s.files       = ["lib/ipinfo_rails.rb"]
  s.homepage    =
    'http://rubygems.org/gems/ipinfo_rails'
  s.license       = 'Apache-2.0'

  s.add_runtime_dependency 'IPinfo', '~> 0.1.2'
  s.add_runtime_dependency 'rack', '~> 1.6', '>= 1.6.4'
end
