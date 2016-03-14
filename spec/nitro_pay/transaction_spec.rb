require 'spec_helper'

describe NitroPay::Transaction do
  before(:all) do
    @protocol = 'http://'
    @domain = 'pay.dev:4000'
    @base_url = "#{@protocol}#{@domain}"
    @redirect_link = 'http://up.nitrostart.me/campaigns/2'
    @global_subscription_tid = get_json("#{@base_url}/api/v1/global_subscription")[:tid]
  end

  context 'Proxy' do
    it 'should validate the proxy' do
      uncomment_proxy_yml
      expect(NitroPay.proxy).to_not be_nil
      comment_proxy_yml
    end
  end

  context 'BuyStorePage' do
    # correct Request/Params
    context 'SUCCESS' do
      context 'Denied request' do
        # Denying a subscription update
        describe 'Update recurrent subscription DENIED' do
          # ================    SetUp/Config    ================
          before(:all) do
            NitroPay.debug=true
            NitroPay.test_env=false

            NitroPay.app_id = 1
            NitroPay.secret_key = '12312321312$2a$10$NmV9EysKVLe8ItBdl9CHN.LF05bOuDdoOkmfptdbJs7cuaDWksuUu'

            # Force the amount to be random & to be exact
            amount = Random.rand(99999).to_s
            @amount = "#{amount}00" if amount[amount.length-2, amount.length] != '00'
            @amount = @amount.to_i
            @recurrence_period = NitroPay.enum[:recurrence_periods][:monthly]

            # Test passing no TID & passing specific TID
            transaction_params = {tid: 1, amount: @amount, recurrence_period: @recurrence_period}
            @transaction = NitroPay::Transaction.new transaction_params

            # Send subscription update
            @subscription_update_resp = @transaction.update_subscription
            @subscription_update_full_resp = @transaction.update_subscription nil, true
          end

          it 'should be Hash' do
            expect(@subscription_update_resp).to be_a Hash
          end

          it 'should not have an error' do
            expect(@subscription_update_resp).to include :error
          end

          it 'should resp with SUCCESS (200)' do
            expect(@subscription_update_full_resp.code).to eq(http_success)
          end
        end

        # Denying an unsubscribe
        describe 'Unsubscribe denied' do
          # ================    SetUp/Config    ================
          before(:all) do
            NitroPay.debug=true
            NitroPay.test_env=false

            NitroPay.app_id = 1
            NitroPay.secret_key = '12312321312$2a$10$NmV9EysKVLe8ItBdl9CHN.LF05bOuDdoOkmfptdbJs7cuaDWksuUu'

            # Test passing no TID & passing specific TID
            @transaction_with_tid = NitroPay::Transaction.new tid: 1

            # Send Unsubscribe
            @tid_transaction_resp = @transaction_with_tid.unsubscribe
            @transaction_full_resp = @transaction_with_tid.unsubscribe nil, true
          end

          it 'should be Hash' do
            expect(@tid_transaction_resp).to be_a Hash
          end

          it 'should not have an error' do
            expect(@tid_transaction_resp).to include :error
          end

          it 'should resp with SUCCESS (200)' do
            expect(@transaction_full_resp.code).to eq(http_success)
          end
        end
      end

      context 'Permitted request' do
        # OK StorePage tests
        describe 'Transaction charged' do
          # ================    SetUp/Config    ================
          before(:all) do
            NitroPay.debug=true
            NitroPay.test_env=true

            #  To test it as CAPTURED it mustn't have cents or invalid credit card number!?
            amount = Random.rand(99999).to_s
            amount = "#{amount}00" if amount[amount.length-2, amount.length] != '00'

            # Forcing formatted amount to check if the GEM is sending it with Operator format
            amount.insert amount.length-2, ','

            @store_transaction = NitroPay::Transaction.new({
              card:{
                brand: 'visa',
                cvv: '123',
                expiration_month: '05',
                expiration_year: (Date.today.year+2).to_s,
                number: '4012001037141112',
                holder: Faker::Name.name,
              },

              amount: amount
            })

            # Fake SoldItems added
            @store_transaction.sold_items = fake_sold_items

            # Send StoreCharge
            @resp = @store_transaction.charge_store
          end

          # ================    Tests/Expects/Should   ================
          it 'resp should not be null' do
            expect(@resp).to_not be_nil
          end

          it 'resp must not include error' do
            expect(@resp).to_not include(:error)
          end

          it 'resp should contain the RequestID' do
            request_id = @resp[:request_id]
            expect(request_id).to_not be_nil
            expect(request_id).to be_a Integer
          end

          it 'resp should have a full SUCCESSFUL transaction status' do
            status = @resp[:status]
            expect(status[:name]).to eq('charged')
            expect(status[:code]).to eq(6) # TODO change it to ENUM
            expect(status[:msg].index('Capturada').nil?).to_not be_truthy
          end

          it 'resp should have a full CardObj which is allowed to be stored {:tid, :truncated, :brand}' do
            card = @resp[:card]
            expect(card[:tid]).to be_a Integer
            expect(card[:tid] == 0).to_not be_truthy
            expect(card[:brand]).to eq('visa')
            expect(card[:truncated].index('***')).to_not be_nil
          end

          it 'resp should have the remote reference (TransactionTID)' do
            tid = @resp[:tid]
            expect(tid).to_not be_nil
            expect(tid).to be_a Integer
            expect(tid != 0).to be_truthy
          end

          context 'verifiable trasaction' do
            before(:all) do
              @verified = @store_transaction.verify
            end

            it 'resp must be a charged status' do
              expect(@verified[:status][:code]).to eq(6)
              expect(@verified[:status][:name]).to eq('charged')
            end

            it 'resp must have an array of sold_items' do
              expect(@verified[:sold_items]).to be_a_kind_of Array
            end
          end
        end

        # TRANSACTION DENIED example
        describe 'Transaction denied' do
          # ================    SetUp/Config    ================
          before(:all) do
            NitroPay.debug=true
            NitroPay.test_env=true

            #  To test it as DENIED it must have cents or invalid credit card number!?
            amount = Random.rand(99999).to_s
            amount = "#{amount}71" if amount[amount.length-2, amount.length] == '00'

            @store_transaction = NitroPay::Transaction.new({
              card:{
                brand: 'visa',
                cvv: '321',
                expiration_month: '05',
                expiration_year: '2018',
                number: '9999999999999999',
                holder: Faker::Name.name,
              },
              recurrence_period_id: NitroPay.enum[:recurrence_periods][:daily],
              amount: amount
            })

            # Fake SoldItems added
            @store_transaction.sold_items = fake_sold_items

            # Send StoreCharge
            @resp = @store_transaction.charge_store
          end

          # ================    Tests/Expects/Should   ================
          it 'resp should not be null' do
            expect(@resp).to_not be_nil
          end

          it 'resp should contain the RequestID' do
            request_id = @resp[:request_id]
            expect(request_id).to_not be_nil
            expect(request_id).to be_a Integer
          end

          it 'resp should have a full SUCCESSFUL transaction status' do
            status = @resp[:status]
            expect(status[:name]).to eq('error')
            expect(status[:code]).to eq(5) # TODO change it to ENUM
            expect(status[:msg].index('não').nil?).to_not be_truthy
          end

          it 'resp should have a full CardObj which is allowed to be stored {:tid, :truncated, :brand}' do
            card = @resp[:card]
            expect(card[:tid]).to be_nil
            expect(card[:brand]).to eq('visa')
            expect(card[:truncated].index('***')).to_not be_nil
          end

          it 'resp should have the remote reference (TransactionTID)' do
            tid = @resp[:tid]
            expect(tid).to_not be_nil
            expect(tid).to be_a Integer
            expect(tid != 0).to be_truthy
          end
        end

        # Create a Subscription (Recurrent charges)
        describe 'Sign a recurrent subscription' do
          # ================    SetUp/Config    ================
          before(:all) do
            NitroPay.debug=true
            NitroPay.test_env=true

            #  To test it as CAPTURED it mustn't have cents or invalid credit card number!?
            amount = Random.rand(99999).to_s
            amount = "#{amount}00" if amount[amount.length-2, amount.length] != '00'

            @store_transaction = NitroPay::Transaction.new({
              card:{
                brand: 'visa',
                cvv: '123',
                expiration_month: '05',
                expiration_year: '2018',
                number: '4012001037141112',
                holder: Faker::Name.name
              },
              recurrence_period_id: NitroPay.enum[:recurrence_periods][:daily],
              amount: amount
            })

            # Fake SoldItems added
            @store_transaction.sold_items = fake_sold_items

            # Send StoreCharge
            @resp = @store_transaction.charge_store
          end

          # ================    Tests/Expects/Should   ================
          it 'resp should not be null' do
            expect(@resp).to_not be_nil
          end

          it 'resp should contain the RequestID' do
            request_id = @resp[:request_id]
            expect(request_id).to_not be_nil
            expect(request_id).to be_a Integer
          end

          it 'resp should have a full SUCCESSFUL transaction status' do
            status = @resp[:status]
            expect(status[:name]).to eq('charged')
            expect(status[:code]).to eq(6) # TODO change it to ENUM
            expect(status[:msg].index('Capturada').nil?).to_not be_truthy
          end

          it 'resp should have a full CardObj which is allowed to be stored {:tid, :truncated, :brand}' do
            card = @resp[:card]
            expect(card[:tid]).to be_a Integer
            expect(card[:tid] == 0).to_not be_truthy
            expect(card[:brand]).to eq('visa')
            expect(card[:truncated].index('***')).to_not be_nil
          end

          it 'resp should have the remote reference (TransactionTID)' do
            tid = @resp[:tid]
            expect(tid).to_not be_nil
            expect(tid).to be_a Integer
            expect(tid != 0).to be_truthy
          end
        end

        # Update a Subscription (Recurrent charges updated)
        describe 'Update the recurrent subscription AMOUNT' do
          # ================    SetUp/Config    ================
          before(:all) do
            NitroPay.debug=true
            NitroPay.test_env=true

            # Force the amount to be random & to be exact
            amount = Random.rand(99999).to_s
            @amount = "#{amount}00" if amount[amount.length-2, amount.length] != '00'
            @amount = @amount.to_i
            @recurrence_period = NitroPay.enum[:recurrence_periods][:monthly]

            # Test passing no TID & passing specific TID
            transaction_params = {amount: @amount, recurrence_period: @recurrence_period}
            @empty_transaction = NitroPay::Transaction.new transaction_params
            transaction_params[:tid] = @global_subscription_tid
            @transaction_with_tid = NitroPay::Transaction.new transaction_params

            # Send subscription update
            @empty_transaction_resp = @empty_transaction.update_subscription
            @tid_transaction_resp = @transaction_with_tid.update_subscription
          end

          it 'should be Hash' do
            expect(@empty_transaction_resp).to be_a Hash
            expect(@tid_transaction_resp).to be_a Hash
          end

          it 'should be performed the unsubscribe' do
            # SetUpVars
            empty_subscription_resp = @empty_transaction_resp[:subscription]
            resp_amount = empty_subscription_resp[:amount]
            resp_recurrence_period = empty_subscription_resp[:recurrence_period]

            # test those attrs
            expect(resp_amount).to eq(@amount)
            expect(resp_recurrence_period).to eq(@recurrence_period)

            # SetUpVars
            tid_subscription_resp = @tid_transaction_resp[:subscription]
            resp_amount = tid_subscription_resp[:amount]
            resp_recurrence_period = tid_subscription_resp[:recurrence_period]

            # test those attrs
            expect(resp_amount).to eq(@amount)
            expect(resp_recurrence_period).to eq(@recurrence_period)
          end

          it 'should not have any error' do
            expect(@empty_transaction_resp).to_not include :error
            expect(@tid_transaction_resp).to_not include :error
          end
        end

        # Unsubscribe a recurrence payment / signature
        describe 'Unsubscribe a recurrent subscription' do
          # ================    SetUp/Config    ================
          before(:all) do
            NitroPay.debug=true
            NitroPay.test_env=true

            # Test passing no TID & passing specific TID
            @empty_transaction = NitroPay::Transaction.new
            @transaction_with_tid = NitroPay::Transaction.new tid: @global_subscription_tid

            # Send Unsubscribe
            @empty_transaction_resp = @empty_transaction.unsubscribe
            @tid_transaction_resp = @transaction_with_tid.unsubscribe
          end

          it 'should be Hash' do
            expect(@empty_transaction_resp).to be_a Hash
            expect(@tid_transaction_resp).to be_a Hash
          end

          it 'should be performed the unsubscribe' do
            expect(@empty_transaction_resp[:did_unsubscribe]).to be_truthy
            expect(@tid_transaction_resp[:did_unsubscribe]).to be_truthy
          end

          it 'should not have any error' do
            expect(@empty_transaction_resp).to_not include :error
            expect(@tid_transaction_resp).to_not include :error
          end
        end

        # Should return all the bank transaction payments done
        describe 'Subscription payment history' do
          # ================    SetUp/Config    ================
          before(:all) do
            NitroPay.debug=true
            NitroPay.test_env=true

            # Test passing no TID & passing specific TID
            @transaction = NitroPay::Transaction.new

            # Send Unsubscribe
            @transaction_resp = @transaction.payment_history
          end

          it 'should be an array' do
            expect(@transaction_resp).to be_a Array
          end

          it 'should not have any error' do
            expect(@transaction_resp.first).to_not include :error
          end

          it 'should have the valid bank_transactions_payment format on it array' do
            transaction = @transaction_resp.first
            valid_keys = [
                :amount, :active, :brand,
                :currency_iso, :status_code, :status_message,
                :next_transaction_at, :created_at, :updated_at
            ]

            valid_keys.each {|key| expect(transaction[key]).to_not be_nil}
          end
        end

        # Should retrieve it only bank transaction done
        describe 'Non-subscription payment history' do
          # ================    SetUp/Config    ================
          before(:all) do
            NitroPay.debug=true
            NitroPay.test_env=true

            # Test passing no TID & passing specific TID
            global_sample_transaction = get_json("#{@base_url}/api/v1/global_sample_transaction")
            @transaction = NitroPay::Transaction.new tid: global_sample_transaction[:id]

            # Send Unsubscribe
            @transaction_resp = @transaction.payment_history
          end

          it 'should be a simple hash' do
            expect(@transaction_resp).to be_a Hash
          end

          it 'should not have any error' do
            expect(@transaction_resp).to_not include :error
          end

          it 'should have the valid bank_transactions_payment format' do
            valid_keys = [
                :amount, :active, :brand,
                :currency_iso, :status_code, :status_message,
                :created_at, :updated_at
            ]

            invalid_keys = [
                :next_transaction_at, :recurrence_period_id
            ]

            valid_keys.each {|key| expect(@transaction_resp[key]).to_not be_nil}
            invalid_keys.each {|key| expect(@transaction_resp[key]).to be_nil}
          end
        end

        # Check if a subscription is up-to-date
        describe 'Up-to-date subscription' do
          # ================    SetUp/Config    ================
          before(:all) do
            NitroPay.debug=true
            NitroPay.test_env=true

            # Test passing no TID & passing specific TID

            @transaction = NitroPay::Transaction.new

            # Send Unsubscribe
            @transaction_resp = @transaction.up_to_date
          end

          it 'should be Hash' do
            expect(@transaction_resp).to be_a Hash
          end

          it 'should be up-to-date with success message' do
            expect(@transaction_resp[:success]).to_not be_nil
          end

          it 'should not have any error' do
            expect(@transaction_resp).to_not include :error
          end
        end

        # Check if a subscription is up-to-date
        describe 'Subscription PENDING payment, not up-to-date' do
          # ================    SetUp/Config    ================
          before(:all) do
            NitroPay.debug=true
            NitroPay.test_env=true

            # Test pending subscription payment passing specific TID
            @global_pending_subscription = get_json("#{@base_url}/api/v1/global_pending_subscription")
            @transaction_with_tid = NitroPay::Transaction.new tid: @global_pending_subscription[:id]

            # Send Unsubscribe
            @tid_transaction_resp = @transaction_with_tid.up_to_date
          end

          it 'should be Hash' do
            expect(@tid_transaction_resp).to be_a Hash
          end

          it 'should not have any error' do
            expect(@tid_transaction_resp).to_not include :error
          end

          it 'should have the subscription' do
            expect(@tid_transaction_resp[:subscription]).to_not be_nil
          end
        end
      end
    end

    # incorrect Request/Params
    context 'BAD REQUEST' do
      # NOT_OK on the authentication Store Page tests
      describe 'Authentication failing' do
        # SetUp/Config
        before(:all) do
          NitroPay.debug = true
          NitroPay.test_env = false
          NitroPay.app_id = 1
          NitroPay.secret_key = '12312321312$2a$10$NmV9EysKVLe8ItBdl9CHN.LF05bOuDdoOkmfptdbJs7cuaDWksuUu'

          amount = Random.rand(99999).to_s
          amount = "#{amount}00" if amount[amount.length-2, amount.length] != '00'

          @store_transaction = NitroPay::Transaction.new({
              card:{
                brand: 'visa',
                cvv: '321',
                expiration_month: '05',
                expiration_year: '2018',
                number: '9999999999999999',
                holder: Faker::Name.name,
              },

              amount: amount
          })

          # Fake SoldItems added
          @store_transaction.sold_items = fake_sold_items

          # Send StoreCharge
          @resp = @store_transaction.charge_store
        end

        # ================    Tests/Expects/Should   ================
        it 'resp should exist (do not be empty)' do
          expect(@resp).to_not be_nil
        end

        it 'resp should contain the RequestID' do
          request_id = @resp[:request_id]
          expect(request_id).to_not be_nil
          expect(request_id).to be_a Integer
        end

        it 'resp should contain auth error' do
          error = @resp[:error].downcase
          expect(error).to_not be_nil
          expect(error.index('auth error').nil?).to_not be_truthy
          expect(error.index('AppID'.downcase).nil?).to_not be_truthy
          expect(error.index('SecretKey'.downcase).nil?).to_not be_truthy
        end
      end
    end
  end

  context 'BuyCheckoutPage' do
    # correct Request/Params
    context 'SUCCESS' do
      # Create CheckoutPage
      describe 'Create CheckoutPage' do
        # ================    SetUp/Config    ================
        before(:all) do
          NitroPay.debug=true
          NitroPay.test_env=true

          #  To test it as CAPTURED it mustn't have cents or invalid credit card number!?
          amount = Random.rand(99999).to_s
          amount = "#{amount}00" if amount[amount.length-2, amount.length] != '00'

          # Forcing formatted amount to check if the GEM is sending it with Operator format
          amount.insert amount.length-2, ','

          @checkout_page_params = {
            title: 'Alfred Robots',
            redirect_link: @redirect_link,
            brand: 'https://s3-sa-east-1.amazonaws.com/global-defaults/nitropay/alfred.png',
            alert: 'Atenção! Você está comprando créditos válidos somente para aquisição de itens do projeto AlfredRobots.',
            description: '<strong>Projeto</strong>: Alfred Robots<br><strong>Tipo da Compra</strong>: Créditos para uso exclusivo neste projeto, após o lançamento do mesmo<br><strong>Descrição</strong>: Seu Robô doméstico de baixo custo, alta eficiência e mais prático.'
          }

          # Perform it page_checkout request
          @checkout_transaction = NitroPay::Transaction.new(@checkout_page_params)
          @full_resp = @checkout_transaction.charge_page(full_resp=true)
          @resp = JSON.parse(@full_resp).it_keys_to_sym
        end

        # ================    Tests/Expects/Should   ================
        it 'resp should not be null' do
          expect(@resp).to_not be_nil
        end

        it 'resp should contain the RequestID' do
          request_id = @resp[:request_id]
          expect(request_id).to_not be_nil
          expect(request_id).to be_a Integer
        end

        it 'resp must have a checkout_page url' do
          checkout_page = @checkout_transaction.checkout_page_url
          expect(checkout_page).to_not be_nil
          expect(accessible?(checkout_page)).to be_truthy
        end
      end
    end

    # incorrect Request/Params
    context 'BAD REQUEST' do
      # NOT_OK on the authentication Store Page tests
      describe 'Authentication failing' do
        # SetUp/Config
        before(:all) do
          NitroPay.debug = true
          NitroPay.test_env = false
          NitroPay.app_id = 1
          NitroPay.secret_key = '12312321312$2a$10$NmV9EysKVLe8ItBdl9CHN.LF05bOuDdoOkmfptdbJs7cuaDWksuUu'

          amount = Random.rand(99999).to_s
          amount = "#{amount}00" if amount[amount.length-2, amount.length] != '00'

          @store_transaction = NitroPay::Transaction.new({
                                                             card:{
                                                                 brand: 'visa',
                                                                 cvv: '321',
                                                                 expiration_month: '05',
                                                                 expiration_year: '2018',
                                                                 number: '9999999999999999',
                                                                 holder: Faker::Name.name,
                                                             },

                                                             amount: amount
                                                         })

          # Fake SoldItems added
          @store_transaction.sold_items = fake_sold_items

          # Send StoreCharge
          @resp = @store_transaction.charge_store
        end

        # ================    Tests/Expects/Should   ================
        it 'resp should exist (do not be empty)' do
          expect(@resp).to_not be_nil
        end

        it 'resp should contain the RequestID' do
          request_id = @resp[:request_id]
          expect(request_id).to_not be_nil
          expect(request_id).to be_a Integer
        end

        it 'resp should contain auth error' do
          error = @resp[:error].downcase
          expect(error).to_not be_nil
          expect(error.index('auth error').nil?).to_not be_truthy
          expect(error.index('AppID'.downcase).nil?).to_not be_truthy
          expect(error.index('SecretKey'.downcase).nil?).to_not be_truthy
        end
      end
    end
  end

  context 'Remote sample connection test' do
    before(:all) do
      NitroPay.debug=false
      NitroPay.test_env=false
      @remote = NitroPay::Status.new
    end

    it 'must have a JSON response' do
      expect(@remote.response).to be_a Hash
    end

    it 'must have a message' do
      expect(@remote.message).to be_a String
    end

    it 'must have an API code' do
      expect(@remote.api_code).to be_a Integer
    end
  end
end