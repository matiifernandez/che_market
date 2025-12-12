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
end
