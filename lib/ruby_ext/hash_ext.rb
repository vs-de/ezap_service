class Hash

  #just quick implement some handy rails funcs(similar)
  #in place, not recursive
  def symbolize_keys!
    keys.each do |k|
      self[k.to_sym] = self.delete(k)
    end
    self
  end

  #in place recursive
  def symbolize_keys_rec!
    keys.each do |k|
      v = self.delete(k)
      self[k.to_sym] = v.is_a?(Hash) ? v.symbolize_keys_rec! : v
    end
    self
  end

end
