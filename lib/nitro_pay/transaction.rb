module NitroPay
  # Transaction Obj, but can Abstract nested objs like Costumer
  class Transaction < NitroPay::Connection
    attr_accessor :tid
    attr_accessor :resp
    attr_accessor :status # can be API Status: self.status = NitroPay::Status.new OR/AND Transaction Status
    attr_accessor :sold_items

    # Constructor
    def initialize(params = {})
      super # super init call
      # Base redirect_link if test_env is set (so the redirect is just appended)
      self.redirect_link = "#{self.end_point_versioned}/transactions" if params[:test_env]
    end

    # Return it Purchase URL, to pay on the OperatorPage
    def checkout_page_url
      hash_resp[:checkout_page]
    end

    # GET /api/transactions/:tid by it attr
    def verify
      auth_hash = {}
      tid = self.resp[:tid]
      auth_hash[:auth] = self.request_params[:auth]
      if tid.nil? then return {error:'TID not received'} else self.path = "transactions/#{tid}#{auth_hash.it_keys_to_get_param}" end
      return self.get_json_request
    end

    def unformed_received_amount
      NitroPay::Currency.to_operator_str self.hash_resp[:amount].to_s
    end

    # POST /api/transactions/page return operator page URL, like the Cielo Page
    def charge_page(full_resp=false)
      custom_http_params(skip_formatters=true)
      # SetUp redirect dynamic if is test
      self.request_params[:transaction][:redirect_link] = "#{self.redirect_link}" if self.request_params[:transaction][:test_env]

      # dynamic path (it is written when a specific method use it)
      self.path = 'checkouts'

      # using json_request because need only the answer (do not use something like it HTTP Code)
      self.resp = self.post_json_request unless full_resp
      self.resp = self.post_request if full_resp
      self.resp
    end

    # POST /api/transactions
    def charge_store(full_resp=false)
      custom_http_params

      # dynamic path (it is written when a specific method use it)
      self.path = 'transactions/store'

      # using json_request because need only the answer (do not use something like it HTTP Code)
      full_resp ? self.resp = self.post_request : self.resp = self.post_json_request

      # return it received resp
      self.resp
    end

    # Update the recurrence amount
    def update_subscription(tid=nil, full_resp=false)
      # SetUp
      self.recurrent_tid = tid if tid
      self.path = "transactions/#{self.recurrent_tid}/subscription"

      # Perform the request
      full_resp ? self.resp = self.put_request : self.resp = self.put_json_request

      # return it received resp
      self.resp
    end

    # Stop a recurrence based on it transaction tid
    def unsubscribe(tid=nil, full_resp=false)
      # SetUp
      self.recurrent_tid = tid if tid
      self.path = "transactions/#{self.recurrent_tid}/subscription/unsubscribe"

      # Perform the request
      full_resp ? self.resp = self.delete_request : self.resp = self.delete_json_request

      # return it received resp
      self.resp
    end

    # Return the payments executed for the purchase passed
    def payment_history(tid=nil, full_resp=false)
      # SetUp
      self.recurrent_tid = tid if tid
      self.path = "transactions/#{self.recurrent_tid}/subscription/payment_history"
      self.path = "#{self.path}#{self.request_params.it_keys_to_get_param}"

      # Perform the request
      full_resp ? self.resp = self.get_request : self.resp = self.get_json_request

      # return it received resp
      self.resp
    end

    # Check if a subscription is up-to-date or have any pending
    def up_to_date(tid=nil, full_resp=false)
      # SetUp
      self.recurrent_tid = tid if tid

      # Create/customize the path & add the auth as param
      self.path = "transactions/#{self.recurrent_tid}/subscription/up-to-date"
      self.path = "#{self.path}#{self.request_params.it_keys_to_get_param}"

      # Perform the request
      full_resp ? self.resp = self.get_request : self.resp = self.get_json_request

      # return it received resp
      self.resp
    end

    # return it hash resp when resp is a string
    def hash_resp
      self.resp.is_a?(String) ? JSON.parse(self.resp).it_keys_to_sym : self.resp
    end

    # ================ STATIC methods ================
    # GET /api/transactions/:tid by the tid passed
    def self.find(tid)
    end
  end
end