class Array
  # Convert string keys to symbol keys
  def it_keys_to_sym
    self.each_with_index {|element, i| element.is_a?(Hash) ? self[i] = element.it_keys_to_sym : next }
  end
end