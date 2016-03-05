require 'spec_helper'

describe NitroPay::Status do
  describe 'API' do
    it 'should be running correctly' do
      NitroPay.debug=true
      NitroPay.test_env=true

      status = NitroPay::Status.new
      expect(status.http_code).to equal(200)
      expect(status.api_code).to equal(200)
      expect(status.message).not_to be nil
    end
  end
end