# frozen_string_literal: true

require_relative "../test_helper"

class ProtectedEnvTest < ActiveSupport::TestCase
  extend ::ActiveSupport::Testing::Declarative

  class TestClass
    include RailsSQLPrettifier::ProtectedEnv
  end

  def setup
    @test_instance = TestClass.new
  end

  test "protected_env? returns false when database does not exist" do
    connection = ActiveRecord::Base.connection

    connection.stub(:database_exists?, false) do
      assert_equal false, @test_instance.protected_env?
    end
  end

end
