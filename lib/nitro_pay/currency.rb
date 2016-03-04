module NitroPay
  # Currency Obj, useful methods to work with many different countries
  class Currency
    # Receive it amount in Decimal and convert to operator str, like 10,00 or 10.00 to 1000
    def self.to_operator_str(amount)
      # Check invalid entry
      return nil if amount.nil?
      return amount.to_s if amount.is_a?Integer
      amount = format('%.2f', amount) if amount.to_s.float?
      return amount if amount.is_a?(String) && amount.index('.').nil? && amount.index(',').nil?

      if amount.is_a?String
        return amount if amount.index('.').nil? && amount.index(',').nil?

        amount = amount.remove('.')
        amount = amount.remove(',')

        return amount
      end

      # Convert from BigDecimal
      if amount.is_a?BigDecimal
        aux_amount_str = amount.to_s('F')
        cents = aux_amount_str[aux_amount_str.index('.'), aux_amount_str.length]

        # Check if there is a bug because the Decimal didn't recognize the second 0
        aux_amount_str = "#{aux_amount_str}0"if cents.index('.')

        return aux_amount_str.remove('.')
      end

      # Create the amount as String
      amount.is_a?(String) ? amount_str = amount : amount_str = amount.to_s
      amount_str_not_formatted = amount_str.remove('.').remove(',')

      # Create the full value
      cents_value = amount_str_not_formatted[amount_str_not_formatted.length-2, amount_str_not_formatted.length-1]
      integer_value = amount_str_not_formatted[0, amount_str_not_formatted.length-2]

      # The return constraint
      "#{integer_value}#{cents_value}"
    end

    # Receive it amount in Integer String (like 1000 that means 10,00 or 10.00) and convert to Decimal value
    def self.to_decimal(amount)
      # If it was passed a BigDecimal it must be passed to operator format
      amount = Currency.to_operator_str(amount) if amount.is_a?BigDecimal

      # Base vars
      aux_amount = amount
      cents_chars_counter = 2

      # Building the currency str like BigDecimal understands
      cents_str = aux_amount[aux_amount.length-cents_chars_counter..aux_amount.length]
      integer_str = aux_amount[0, aux_amount.length-cents_chars_counter]
      new_amount = "#{integer_str}.#{cents_str}"

      BigDecimal.new new_amount
    end

    # Get it cents from operator amount formatted
    def self.get_cents(amount)
      aux = amount.to_s
      cents_length = 2
      aux[aux.length-cents_length, aux.length]
    end

    # Receive a numeric form operator format & retrieve it
    def self.have_cents?(amount)
      aux = "#{amount.to_f/100}" if amount.is_a?(String) || amount.is_a?(Integer)
      aux = amount.to_s if amount.is_a?Float
      cents = aux[aux.index('.')+1, aux.length]
      cents.length == 2 ? true : false
    end
  end
end