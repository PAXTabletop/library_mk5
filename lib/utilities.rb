module Utilities

  def self.capitalize(string)
    string.split(' ').map(&:capitalize).join(' ')
  end

  def self.BARCODE_FORMAT
    /\A[a-z0-9]{3,13}\Z/i
  end

end