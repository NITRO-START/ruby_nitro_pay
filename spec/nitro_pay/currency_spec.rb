require 'spec_helper'

describe NitroPay::Currency do
  describe 'Operator Format value' do
    # setup it vars to have the conversion tested, value: 1999 (nineteen ninety nine)
    pt_br = '1.999,00'
    en_us = '1,999.00'
    non_formatted = '199900'
    non_formatted_with_cents = '199933'

    # Values expected
    cents_expected = '55'
    non_cents_expected = '00'
    operator_value = non_formatted
    integer_value = non_formatted.to_i
    operator_expected_value = '199900'
    decimal_value = BigDecimal.new '1999.00'
    operator_with_cents = '300055' # R$ 3.000,55
    decimal_expected_value = BigDecimal.new '1999.00'
    expected_float_unit_cents = '100005'
    expected_float_decimal_cents = '100050'
    expected_float_without_cents = '100000'

    # Float values
    float_with_cents = 1000.55
    float_without_cents = 1000.00

    float_unit_cents = 1000.05
    float_decimal_cents = 1000.50

    # Values Converted to operator format
    non_cents_received = NitroPay::Currency.get_cents operator_value
    decimal_converted = NitroPay::Currency.to_decimal operator_value
    cents_received = NitroPay::Currency.get_cents operator_with_cents
    pt_br_operator_converted = NitroPay::Currency.to_operator_str pt_br
    en_us_operator_converted = NitroPay::Currency.to_operator_str en_us
    integer_converted = NitroPay::Currency.to_operator_str integer_value
    big_decimal_converted = NitroPay::Currency.to_operator_str decimal_value
    non_formatted_converted = NitroPay::Currency.to_operator_str non_formatted
    non_formatted_with_cents_converted = NitroPay::Currency.to_operator_str non_formatted_with_cents
    float_unit_cents_conv = NitroPay::Currency.to_operator_str float_unit_cents
    float_decimal_cents_conv = NitroPay::Currency.to_operator_str float_decimal_cents
    float_without_cents_conv = NitroPay::Currency.to_operator_str float_without_cents

    context 'Decimal to Operator' do
      # Convert PT_BR
      it 'PT_BR should be convertible' do
        expect(pt_br_operator_converted).to be_a String
        expect(pt_br_operator_converted.index('.')).to be_nil
        expect(pt_br_operator_converted.index(',')).to be_nil
        expect(pt_br_operator_converted).to be_integer
        expect(pt_br_operator_converted).to be_equals operator_expected_value
      end

      # Convert EN_US
      it 'EN_US should be convertible' do
        expect(en_us_operator_converted).to be_a String
        expect(en_us_operator_converted.index('.')).to be_nil
        expect(en_us_operator_converted.index(',')).to be_nil
        expect(en_us_operator_converted).to be_integer
        expect(en_us_operator_converted).to be_equals operator_expected_value
      end

      # To operator passing a BigDecimal instance
      it 'should have a Operator format based on BigDecimal instance' do
        expect(big_decimal_converted).to be_a String
        expect(big_decimal_converted.index('.')).to be_nil
        expect(big_decimal_converted.index(',')).to be_nil
        expect(big_decimal_converted).to be_integer
        expect(big_decimal_converted).to be_equals operator_expected_value
      end
    end

    context 'Integer to Operator' do
      it 'should have a Operator format based on Integer instance' do
        expect(integer_converted).to be_a String
        expect(integer_converted.index('.')).to be_nil
        expect(integer_converted.index(',')).to be_nil
        expect(integer_converted).to be_integer
        expect(integer_converted).to be_equals operator_expected_value
      end
    end

    context 'Float to Operator' do
      it 'unit cents con must be on Operator format' do
        expect(float_unit_cents_conv).to be == expected_float_unit_cents
      end

      it 'decimal cents con must be on Operator format' do
        expect(float_decimal_cents_conv).to be == expected_float_decimal_cents
      end

      it 'no cents must be an Operator format' do
        expect(float_without_cents_conv).to be == expected_float_without_cents
      end
    end

    context 'Operator to Decimal' do
      # Convert from the operator to BigDecimal instance, like rails does/need
      it 'should be the BigDecimal expected' do
        expect(decimal_converted).to be_a BigDecimal
        expect(decimal_converted).to be == decimal_expected_value.to_i
      end
    end

    context 'Non-formatted value to operator' do
      context 'without cents' do
        it 'must be the same as received' do
          expect(non_formatted_converted).to be == non_formatted
        end

        it 'cents must be the same' do
          expect(NitroPay::Currency.get_cents(non_formatted_converted)).to be == NitroPay::Currency.get_cents(non_formatted)
        end
      end

      context 'with cents' do
        it 'must be the same as received' do
          expect(non_formatted_with_cents_converted).to be == non_formatted_with_cents
        end

        it 'cents must be the same' do
          expect(NitroPay::Currency.get_cents(non_formatted_with_cents_converted)).to be == NitroPay::Currency.get_cents(non_formatted_with_cents)
        end
      end
    end

    context 'Methods to work in operator format' do
      it 'should retrieve existent cents' do
        expect(cents_received).to be_equals cents_expected
      end

      it 'should retrieve the non existent cents' do
        expect(non_cents_received).to be_equals non_cents_expected
      end

      it 'should have cents' do
        expect(NitroPay::Currency.have_cents?(operator_with_cents)).to be_truthy
      end

      it 'should not have cents' do
        expect(NitroPay::Currency.have_cents?(operator_value)).to_not be_truthy
      end

      it '(RECEIVING FLOAT) should have cents' do
        expect(NitroPay::Currency.have_cents?(float_with_cents)).to be_truthy
      end

      it '(RECEIVING FLOAT) should not have cents' do
        expect(NitroPay::Currency.have_cents?(float_without_cents)).to_not be_truthy
      end
    end
  end
end