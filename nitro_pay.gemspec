# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nitro_pay/version'

Gem::Specification.new do |spec|
  spec.name          = 'nitro_pay'
  spec.version       = NitroPay::VERSION
  spec.authors       = ['Ilton Garcia']
  spec.email         = ['ilton_unb@hotmail.com']

  spec.summary       = 'NitroPay the NITRO START Gateway & Intermediary Payments ruby gem'
  spec.description   = 'With NitroPay your payments get cheaper, faster & simplified. Create your Account on our WebSite or Start your StartUp on NITRO START.'
  spec.homepage      = 'http://pay.nitrostart.me'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  #================== GEMs to build it GEM, so its improve the development ==============================
  # Base GEMs to build it gem
  spec.add_development_dependency 'bundler', '~> 1.11', '>= 1.11.2'
  spec.add_development_dependency 'rake', '~> 10.5'

  # RSpec for tests
  spec.add_development_dependency 'rspec', '~> 3.4'
  # Coverage
  spec.add_development_dependency 'simplecov', '~> 0.11.2'
  # Create readable attrs values
  spec.add_development_dependency 'faker', '~> 1.6', '>= 1.6.3'
  # CPF/CNPJ fake it
  spec.add_development_dependency 'cpf_cnpj', '~> 0.2.1'

  #================== GEMs to be used when it is called on a project ====================================
  # For real user operator IP (4GeoLoc)
  spec.add_dependency 'curb', '~> 0.9.1'
  # HTTP REST Client
  spec.add_dependency 'rest-client', '~> 1.8'
  # Easy JSON create
  spec.add_dependency 'multi_json', '~> 1.11', '>= 1.11.2'
  # To pretty print on console
  spec.add_dependency 'colorize', '~> 0.7.7'
  # To work with the Rails Numeric for currency
  spec.add_dependency 'bigdecimal', '~> 1.2', '>= 1.2.7'
end
