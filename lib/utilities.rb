module Utilities

  def self.capitalize(string)
    string.split(' ').map(&:capitalize).join(' ')
  end

  def self.BARCODE_FORMAT
    /\A[a-z]{3}\d{3,5}[a-z0-9]{2}\Z/i
  end

end