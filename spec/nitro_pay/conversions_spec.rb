=begin
  require 'spec_helper'

  describe 'Numeric conversions' do
    describe 'BigDecimalBackup conversions' do
      # setup it vars to have the conversion tested, value: 1999 (nineteen ninety nine)
      pt_br = '1.999,00'
      en_us = '1,999.00'

      # Value like the card operator uses
      operator_expected_value = '199900'
      operator_value = '199900'
      decimal_expected_value = BigDecimal.new '1999.00'

      # it is the Rails conversion form the Form for Decimal input
      decimal_obj_pt_br = BigDecimal.new(pt_br)
      decimal_obj_en_us = BigDecimal.new(en_us.remove('.').remove(','))

      # Conversions
      pt_br_converted = Currency.to_operator_str decimal_obj_pt_br
      en_us_converted = Currency.to_operator_str decimal_obj_en_us
      decimal_converted = Currency.to_decimal operator_value

      context 'Operator Format value' do

      end

      it 'should be running correctly' do
        status = NitroPay::Status.new
        expect(status.http_code).to equal(200)
        expect(status.api_code).to equal(200)
        expect(status.message).not_to be nil
      end
    end
  end
=end