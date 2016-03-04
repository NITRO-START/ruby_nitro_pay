# encoding: utf-8

# TODO if using Rails 4 or greater use copy and paste on your secret.yml:
# nitro_pay:
#   app_id: # TODO your app_id
#   app_secret_key: # TODO your app_secret_key
# IMPORTANT: remember that test & development is not necessary if using test_env, but if you want your test app remember to use you test_app id & secret

# It automatic the NitroPay to it TestEnv & ProductionEnv
if Rails.env.development? || Rails.env.test?
  # TODO if using Rails 3 or older & not using the TEST_ENV, put here your TEST app_id & your secret_key
  NitroPay.app_id = ''
  NitroPay.secret_key = ''

  # TODO: Uncomment test_env if you want to test using NitroPay default & global app
  # NitroPay.test_env = true
  # TODO: Uncomment debugger if you have an NitroPay instance on your machine
  # NitroPay.debug = true
elsif Rails.env.production?
  # TODO if using Rails 3 or older, put here your PRODUCTION app_id & your secret_key
  NitroPay.app_id = ''
  NitroPay.secret_key = ''

  # For production remember to keep it false or just remove it
  NitroPay.debug = false
  NitroPay.test_env = false
end

# Get your App config if your not using TEST_ENV nor DEBUGGER
if (NitroPay.test_env.nil? && NitroPay.debug.nil?) || (NitroPay.test_env == false && NitroPay.debug == false)
  if Rails.version[0].to_i >= 4
    begin
      NitroPay.app_id = Rails.application.secrets.NitroPay['app_id']
      NitroPay.secret_key = Rails.application.secrets.NitroPay['app_secret_key']
    rescue
      p 'Check your Secret.yml... Please add on it your Rent$ app_id & app_secret_key'
    end
  end
end
