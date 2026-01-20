# frozen_string_literal: true

module RailsSQLPrettifier
  module ProtectedEnv
    def protected_env?
      migration_context = ActiveRecord::Base.connection.try(:migration_context) ||
        ActiveRecord::Base.connection.try(:pool)&.migration_context # rails 7.2+

      if ActiveRecord::Base.connection.database_exists?
        migration_context&.protected_environment? ||
          defined?(Rails) && !(Rails.env.test? || Rails.env.development?)
      else
        false
      end
    end
  end
end
