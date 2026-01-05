# frozen_string_literal: true

require "test_helper"

# Test class that includes the ProtectedEnv module
class ProtectedEnvTester
  include RailsSQLPrettifier::ProtectedEnv
end

unless defined?(Rails)
  module Rails
    def self.env; end
  end
end

class ProtectedEnvTest < Minitest::Test
  extend ::ActiveSupport::Testing::Declarative

  def setup
    @tester = ProtectedEnvTester.new
  end

  def mock_connection(migration_context: nil, pool_migration_context: nil)
    connection = Minitest::Mock.new
    pool = Minitest::Mock.new

    if migration_context
      connection.expect(:try, migration_context, [:migration_context])
    else
      connection.expect(:try, nil, [:migration_context])
      if pool_migration_context
        pool.expect(:migration_context, pool_migration_context)
        connection.expect(:try, pool, [:pool])
      else
        connection.expect(:try, nil, [:pool])
      end
    end

    connection
  end

  def mock_migration_context(protected:)
    migration_context = Minitest::Mock.new
    migration_context.expect(:protected_environment?, protected)
    migration_context
  end

  test "returns true when migration_context.protected_environment? is true" do
    migration_context = mock_migration_context(protected: true)
    connection = mock_connection(migration_context: migration_context)

    ActiveRecord::Base.stub(:connection, connection) do
      assert(@tester.protected_env?)
    end
  end

  test "returns false when migration_context.protected_environment? is false and Rails is in test env" do
    migration_context = mock_migration_context(protected: false)
    connection = mock_connection(migration_context: migration_context)

    ActiveRecord::Base.stub(:connection, connection) do
      Rails.stub(:env, ActiveSupport::EnvironmentInquirer.new("test")) do
        refute(@tester.protected_env?)
      end
    end
  end

  test "returns false when migration_context.protected_environment? is false and Rails is in development env" do
    migration_context = mock_migration_context(protected: false)
    connection = mock_connection(migration_context: migration_context)

    ActiveRecord::Base.stub(:connection, connection) do
      Rails.stub(:env, ActiveSupport::EnvironmentInquirer.new("development")) do
        refute(@tester.protected_env?)
      end
    end
  end

  test "returns true when migration_context.protected_environment? is false but Rails is in production env" do
    migration_context = mock_migration_context(protected: false)
    connection = mock_connection(migration_context: migration_context)

    ActiveRecord::Base.stub(:connection, connection) do
      Rails.stub(:env, ActiveSupport::EnvironmentInquirer.new("production")) do
        assert(@tester.protected_env?)
      end
    end
  end

  test "returns true when migration_context is nil but Rails is in production env" do
    connection = mock_connection(migration_context: nil, pool_migration_context: nil)

    ActiveRecord::Base.stub(:connection, connection) do
      Rails.stub(:env, ActiveSupport::EnvironmentInquirer.new("production")) do
        assert(@tester.protected_env?)
      end
    end
  end

  test "returns false when ActiveRecord::NoDatabaseError is raised" do
    migration_context = Minitest::Mock.new
    migration_context.expect(:protected_environment?, nil) do
      raise ActiveRecord::NoDatabaseError
    end
    connection = mock_connection(migration_context: migration_context)

    ActiveRecord::Base.stub(:connection, connection) do
      refute(@tester.protected_env?)
    end
  end

  test "uses pool.migration_context for Rails 7.2+ when connection.migration_context is nil" do
    pool_migration_context = mock_migration_context(protected: true)
    connection = mock_connection(migration_context: nil, pool_migration_context: pool_migration_context)

    ActiveRecord::Base.stub(:connection, connection) do
      assert(@tester.protected_env?)
    end
  end

  test "returns false when Rails is not defined and migration_context is nil" do
    connection = mock_connection(migration_context: nil, pool_migration_context: nil)

    ActiveRecord::Base.stub(:connection, connection) do
      # Temporarily hide Rails constant
      rails_const = Object.send(:remove_const, :Rails)
      begin
        refute(@tester.protected_env?)
      ensure
        Object.const_set(:Rails, rails_const)
      end
    end
  end
end
