module ApplicationHelper
  def format_currency(amount)
    return 'K0.00' if amount.nil?

    "K#{number_with_precision(amount, precision: 2, delimiter: ',')}"
  end

  def format_currency_short(amount)
    return 'K0' if amount.nil?

    "K#{number_with_precision(amount, precision: 0, delimiter: ',')}"
  end
end
