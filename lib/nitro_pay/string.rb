class String
  def remove(pattern)
    gsub pattern, ''
  end

  def integer?
    self.to_i.to_s == self
  end

  def float?
    self.to_f.to_s == self
  end

  def equals?(str)
    self == str
  end
end