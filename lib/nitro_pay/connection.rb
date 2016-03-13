module NitroPay
  class Connection
    # Attrs
    attr_accessor :auth
    attr_accessor :path
    attr_accessor :domain
    attr_accessor :protocol
    attr_accessor :end_point
    attr_accessor :api_version
    attr_accessor :recurrent_tid
    attr_accessor :request_params
    attr_accessor :end_point_versioned

    # Constructor
    def initialize(params = {})
      # An work around added to prevent a lot of changes
      params = params.merge({test_env:true}) if NitroPay.test_env
      params = params.merge({debug:true}) if NitroPay.debug

      # Static part
      self.request_params = {transaction:params}
      setup_config
      self.domain = 'pay.nitrostart.me'

      # If using test or Debug it is not production
      if params[:debug] || params[:test]
        self.protocol = 'http'
        self.domain = 'pay.dev:4000'
      else
        # TODO when add SSL to Production replace http to https
        self.protocol = 'http'
        self.domain = 'pay.nitrostart.me'
      end

      self.api_version = 'v1'
      self.end_point = "#{self.protocol}://#{self.domain}/api"
      self.end_point_versioned = "#{self.protocol}://#{self.domain}/api/#{self.api_version}"

      # Dynamic env
      setup_default_app if params[:test_env]
      setup_attrs(params)
      self.recurrent_tid = params[:tid] unless params[:tid].nil?
    end

    # Full URL for the last request
    def url_requested
      "#{self.end_point}/#{self.api_version}/#{self.path}"
    end

    # GET http
    def get_request
      RestClient.get self.url_requested
    end

    # GET json
    def get_json_request
      resp = RestClient.get(self.url_requested)
      to_hash_with_symbols(resp).it_keys_to_sym
    end

    # POST http
    def post_request
      RestClient.post self.url_requested, self.request_params
    end

    # POST json
    def post_json_request
      resp = RestClient.post(self.url_requested, self.request_params)
      to_hash_with_symbols(resp)
    end

    # PUT http
    def put_request
      RestClient.put self.url_requested, self.request_params
    end

    # PUT json
    def put_json_request
      resp = RestClient.put(self.url_requested, self.request_params)
      to_hash_with_symbols(resp)
    end

    # DELETE http
    def delete_request
      auth = self.request_params[:auth]
      RestClient.delete self.url_requested, app_id:auth[:app_id], secret_key:auth[:secret_key]
    end

    # DELETE json
    def delete_json_request
      auth = self.request_params[:auth]
      resp = RestClient.delete self.url_requested, auth_app_id:auth[:app_id], auth_secret_key:auth[:secret_key]
      to_hash_with_symbols(resp)
    end

    # Callbacks
    protected
      # Config Attrs
      def setup_config
        self.auth = {app_id:NitroPay.app_id, secret_key:NitroPay.secret_key}
        self.request_params.merge!(auth:self.auth)
      end

      # SetUp a default app
      def setup_default_app
        # setup test_app path
        self.path = 'global_app'

        # Get the App & setup config
        app = get_json_request[:app]
        NitroPay.app_id = app[:id]
        NitroPay.secret_key = app[:secret]

        # Get the GlobalRecurrent & setup/config
        self.path = 'global_subscription'
        recurrence = get_json_request
        self.recurrent_tid = recurrence[:tid]

        return puts 'Please run: rails g nitro_pay:install' if NitroPay.app_id.nil? || NitroPay.secret_key.nil?
        self.auth = {app_id:NitroPay.app_id, secret_key:NitroPay.secret_key}
        self.request_params.merge!(auth:self.auth)
      end

      # SetUp all attrs
      def setup_attrs(params)
        # Dynamic part
        params.each do |key, value|
          next unless key.to_s.index('[]').nil?
          self.class.__send__(:attr_accessor, :"#{key}")
          self.__send__("#{key}=", value)
        end
      end

      # HTTP requests must have '[]' on it key name to send Array
      def custom_http_params(skip_formatters=false)
        setup_format_and_validators unless skip_formatters

        return if self.sold_items.nil?
        self.sold_items.each_with_index do |sold_item, i|
          self.request_params[:transaction]["sold_items[#{i}]"] = sold_item
        end
      end

      # Validate params to prevent errors like BAD Request & format values like value to Operator format
      def setup_format_and_validators
        validate_operator_format
      end

      # if necessary convert amount to operator value
      def validate_operator_format
        # prevent fatal error
        return if self.amount.nil?

        # aux vars
        amount_str = self.amount.to_s
        format_regex = /[.,]/

        # if nil (it is not formatted, so it is not necessary to convert it format)
        unless amount_str.match(format_regex).nil?
          return if self.request_params.nil? || self.request_params[:transaction].nil?
          self.amount = NitroPay::Currency.to_operator_str(self.amount)
          self.request_params[:transaction][:amount] = self.amount
        end
      end
    
      # Return the JSON in a Hash with it keys in symbols
      def to_hash_with_symbols(json)
        hashed = JSON.parse(json)
        hashed.is_a?(Array) ? hashed.each_with_index { |hash, i| hashed[i] = hash.it_keys_to_sym } : hashed.it_keys_to_sym
        hashed
      end
  end
end