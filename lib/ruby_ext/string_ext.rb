
class String
  #TODO: change capitalize with sth that only changes the first letter up, not also others down
  def camelize
    self.split('_').map(&:capitalize).join
  end
end
