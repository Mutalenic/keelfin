# The Ledger namespace isolates the double-entry ledger engine from the rest of
# the Keelfin application. Keeping every ledger model, service and job under this
# module (with `ledger_`-prefixed tables) means the whole engine can later be
# extracted into a standalone mountable Rails engine with minimal effort.
module Ledger
  def self.table_name_prefix
    'ledger_'
  end
end
