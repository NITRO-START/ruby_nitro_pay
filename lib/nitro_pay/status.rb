module NitroPay
  class Status < NitroPay::Connection
    # Attrs
    attr_accessor :message # API response message
    attr_accessor :http_code # HTTP Code for the request
    attr_accessor :api_code # Internal system response code
    attr_accessor :response # the JSON retrieved

    # Constructor
    def initialize(params = {})
      super # call it super initialize
      self.path = 'status'
      check_it
    end

    # Check it status and 'setup' it attrs
    def check_it
      self.path = 'status'
      resp = get_request
      hash_resp = JSON.parse(resp).it_keys_to_sym
      self.http_code = resp.code
      self.message = "EndPoint not response(connection error): #{self.url_requested}" if self.http_code != 200
      self.message = hash_resp[:message] if self.http_code == 200
      self.api_code = hash_resp[:api_code]
      self.response = hash_resp
      self
    end
  end
end