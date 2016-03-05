require 'bundler/setup'
require 'rest_client'
require './spec/helpers'

Bundler.setup

require 'simplecov'
SimpleCov.start do
end

# and any other gems you need
require 'nitro_pay'
require 'faker'
require 'cpf'
require 'cnpj'

RSpec.configure do |c|
  # some (optional) config here
  c.include Helpers
end