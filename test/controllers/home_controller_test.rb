require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  test 'home page is rendered' do
    get :home_page

    assert_response :success
  end
end