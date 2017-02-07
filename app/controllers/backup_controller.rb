class BackupController < ApplicationController

  include DropboxUtil

  def initiate
    result = DropboxUtil.backup

    render status: result[:status], json: { message: result[:message] }
  end

end
