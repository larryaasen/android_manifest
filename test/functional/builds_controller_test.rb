require 'test_helper'

class BuildsControllerTest < ActionController::TestCase
  setup do
    @build = builds(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:builds)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create build" do
    assert_difference('Build.count') do
      post :create, build: @build.attributes
    end

    assert_redirected_to build_path(assigns(:build))
  end

  test "should show build" do
    get :show, id: @build.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @build.to_param
    assert_response :success
  end

  test "should update build" do
    put :update, id: @build.to_param, build: @build.attributes
    assert_redirected_to build_path(assigns(:build))
  end

  test "should destroy build" do
    assert_difference('Build.count', -1) do
      delete :destroy, id: @build.to_param
    end

    assert_redirected_to builds_path
  end
end
