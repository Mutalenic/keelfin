# money-rails configuration. Keelfin is ZMW-first; amounts are always stored as
# integer cents in the ledger.
#
# Note: money-rails' Railtie adds autoload paths. We configure it here rather
# than via the generated initializer to avoid a FrozenError in environments
# where Rails freezes autoload paths before initializers run.
MoneyRails.configure do |config|
  config.default_currency = :zmw
  config.locale_backend   = :i18n
  config.rounding_mode    = BigDecimal::ROUND_HALF_UP
end
