module ApplicationHelper
  include Pagy::Frontend

  def admin_nav_link(text, path, controller_name, badge_count: nil)
    is_active = controller.controller_name == controller_name || (controller_name == "dashboard" && controller.controller_name == "dashboard")

    base_classes = "flex items-center justify-between px-4 py-2 rounded-lg transition duration-200"
    active_classes = is_active ? "bg-indigo-600 text-white" : "text-gray-300 hover:bg-gray-800"

    badge_html = ""
    if badge_count.present? && badge_count > 0
      badge_html = content_tag(:span, badge_count, class: "ml-auto bg-red-500 text-white text-xs font-bold px-2 py-0.5 rounded-full")
    end

    link_to path, class: "#{base_classes} #{active_classes}" do
      concat text
      concat badge_html.html_safe if badge_html.present?
    end
  end
end
