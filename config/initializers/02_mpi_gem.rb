instance = MasterPersonIndex::Configuration.instance

instance.base_path = Settings.mvi.url
instance.ssl_cert_path = Settings.mvi.client_cert_path
instance.ssl_key_path = Settings.mvi.client_key_path
instance.open_timeout = Settings.mvi.open_timeout
instance.read_timeout = Settings.mvi.timeout
instance.processing_code = Settings.mvi.processing_code
instance.vba_orchestration = Settings.mvi.vba_orchestration
instance.edipi_search = Settings.mvi.edipi_search

handlers = instance.connection.builder.handlers

handlers.insert(
  -2,
  Faraday::RackBuilder::Handler.new(
    Common::Client::Middleware::Logging,
    'MVIRequest'
  )
) if Settings.mvi.pii_logging

handlers.insert(
  -2,
  Faraday::RackBuilder::Handler.new(
    Betamocks::Middleware
  )
) if Settings.mvi.mock
