module ApplicationHelper
  include Pagy::Frontend

  def format_currency(amount)
    return 'K0.00' if amount.nil?

    "K#{number_with_precision(amount, precision: 2, delimiter: ',')}"
  end

  def format_currency_short(amount)
    return 'K0' if amount.nil?

    "K#{number_with_precision(amount, precision: 0, delimiter: ',')}"
  end

  def sidebar_link(label, path, icon_class, controller_name_match)
    active = controller_name == controller_name_match
    state_class = if active
                    'bg-accent/10 text-accent'
                  else
                    'text-subtle hover:bg-content/5 hover:text-content'
                  end
    link_class = "flex items-center px-3 py-2.5 rounded-xl text-sm font-medium transition-all #{state_class}"
    link_to path, class: link_class do
      content_tag(:i, nil, class: "#{icon_class} w-5 text-center #{active ? 'text-accent' : 'text-faint'}") +
        content_tag(:span, label, class: 'ml-3')
    end
  end

  def admin_sidebar_link(label, path, icon_class, controller_name_match)
    active = controller_name == controller_name_match
    state_class = active ? 'bg-gray-800 text-white' : 'text-gray-400 hover:bg-gray-800 hover:text-white'
    link_class = "flex items-center px-3 py-2.5 rounded-xl text-sm font-medium transition-all #{state_class}"
    link_to path, class: link_class do
      content_tag(:i, nil, class: "#{icon_class} w-5 text-center #{active ? 'text-brand-400' : 'text-gray-500'}") +
        content_tag(:span, label, class: 'ml-3')
    end
  end
end
