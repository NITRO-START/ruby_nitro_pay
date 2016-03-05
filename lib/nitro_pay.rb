# Libs/Gems or Ruby classes
require 'json'
require 'curl'
require 'yaml'
require 'rest_client'
require 'bigdecimal'
require 'bigdecimal/util'

# Overrides
require 'nitro_pay/hash'
require 'nitro_pay/array'

# Gem files
[:version, :connection, :status, :transaction, :currency, :string].each { |lib| require "nitro_pay/#{lib}" }

module NitroPay
  # Module attr
  @@enum = nil

  # Production settings
  @@app_id = nil
  @@secret_key = nil

  # Tests settings
  @@proxy_yml = nil
  @@test_env = nil
  @@debug = nil

  def self.proxy_yml
    @@proxy_yml = NitroPay.get_proxy_from_yml if @@proxy_yml.nil?
    @@proxy_yml
  end

  def self.proxy
    return nil if NitroPay.proxy_yml.nil? || NitroPay.proxy_yml.empty?
    "http://#{NitroPay.proxy_yml[:login]}:#{NitroPay.proxy_yml[:password]}@#{NitroPay.proxy_yml[:host]}:#{NitroPay.proxy_yml[:port]}/"
  end

  def self.app_id=(app_id)
    @@app_id = app_id
  end

  def self.app_id
    @@app_id
  end

  def self.secret_key=(secret_key)
    @@secret_key = secret_key
  end

  def self.secret_key
    @@secret_key
  end

  def self.test_env
    @@test_env
  end

  def self.test_env=(test_env)
    @@test_env = test_env
  end

  def self.debug
    @@debug
  end

  def self.debug=(debug)
    @@debug = debug
  end

  def self.get_proxy_from_yml
    yml = YAML::load_file(File.join(File.dirname(File.expand_path(__FILE__)), 'nitro_pay/config/proxy.yml'))
    !yml.nil? || yml.is_a?(Hash) ? yml.it_keys_to_sym : {} if yml
  end

  def self.enum
    enum = {}
    return @@enum unless @@enum.nil?

    enum = enum.merge load_yml('brands.yml')
    enum = enum.merge load_yml('currencies.yml')
    enum = enum.merge load_yml('payment_methods.yml')
    enum = enum.merge load_yml('recurrence_periods.yml')
    enum = enum.merge load_yml('transaction_codes.yml')

    enum = enum.it_keys_to_sym
    @@enum = enum
  end

  def self.load_yml(file_name)
    YAML::load_file(File.join(File.dirname(File.expand_path(__FILE__)), 'nitro_pay/config/enums/' + file_name))
  end
end