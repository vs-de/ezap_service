class Class
  def top_class_name
    to_s.gsub(/.*::/,'')
  end
end
