module ApplicationHelper
  def category_emoji(slug)
    emojis = {
      "yerba-mate" => "🧉",
      "dulces" => "🍯",
      "mates-y-bombillas" => "🫖",
      "alfajores" => "🍪",
      "bebidas" => "🍷",
      "snacks" => "🥜"
    }
    emojis[slug] || "📦"
  end

  def admin_nav_link(text, path, controller_name)
    is_active = controller.controller_name == controller_name || (controller_name == "dashboard" && controller.controller_name == "dashboard")

    base_classes = "flex items-center px-4 py-2 rounded-lg transition duration-200"
    active_classes = is_active ? "bg-indigo-600 text-white" : "text-gray-300 hover:bg-gray-800"

    link_to text, path, class: "#{base_classes} #{active_classes}"
  end
end
