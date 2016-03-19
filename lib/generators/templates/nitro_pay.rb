# encoding: utf-8

# Setup NitroPay keys
if Rails.env.production?
  NitroPay.app_id = Rails.application.secrets.nitro_pay.app_id
  NitroPay.secret_key = Rails.application.secrets.nitro_pay.secret_key
else
  # TODO if using Rails 3 or older & not using the TEST_ENV, put here your TEST app_id & your secret_key
  NitroPay.app_id = ''
  NitroPay.secret_key = ''

  # TODO: Uncomment test_env if you want to test using NitroPay default & global app
  # NitroPay.test_env = true
  # TODO: Uncomment debugger if you have an NitroPay instance on your machine
  # NitroPay.debug = true
end