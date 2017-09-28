Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.seconds.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # OmniAuth.config.test_mode = true
  # OmniAuth.config.mock_auth[:france_connect] = OmniAuth::AuthHash.new(
  #   credentials: { token: '1a2z3e4r5t' },
  #   email: 'user@user.user',
  #   provider: 'france_connect',
  #   uid: '123545'
  # )
  # OmniAuth.config.mock_auth[:dgfip] = OmniAuth::AuthHash.new(
  #   credentials: { token: '1a2z3e4r5t' },
  #   info: { email: 'user@user.user' },
  #   provider: 'dgfip',
  #   uid: '123545'
  # )
end
