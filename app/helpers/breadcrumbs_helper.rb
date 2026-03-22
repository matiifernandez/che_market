module BreadcrumbsHelper
  def breadcrumbs
    @breadcrumbs ||= [
      { name: t("breadcrumbs.home"), path: root_path }
    ]
  end

  def add_breadcrumb(name, path = nil)
    breadcrumbs << { name: name, path: path }
  end

  def render_breadcrumbs
    return "" if breadcrumbs.size <= 1 # Don't show if only Home is present

    # JSON-LD data for Breadcrumbs
    json_ld = {
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      "itemListElement": breadcrumbs.map.with_index(1) do |crumb, index|
        item_url = if crumb[:path]
          url_for(crumb[:path], only_path: false)
        else
          request.original_url
        end

        {
          "@type": "ListItem",
          "position": index,
          "name": crumb[:name],
          "item": item_url
        }
      end
    }

    # Visual breadcrumbs using Tailwind (minimalist)
    visual_html = content_tag(:nav, aria: { label: t("breadcrumbs.aria_label") }, class: "flex mb-6") do
      content_tag(:ol, class: "inline-flex items-center space-x-1 md:space-x-3 text-sm") do
        safe_join(
          breadcrumbs.map.with_index do |crumb, index|
            content_tag(:li, class: "inline-flex items-center") do
              parts = []
              # Arrow separator for all items except the first one
              parts << content_tag(
                :svg,
                content_tag(:path, nil, d: "M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"),
                class: "w-4 h-4 text-gray-400 mx-1",
                fill: "currentColor",
                viewBox: "0 0 20 20",
                aria: { hidden: "true" },
                focusable: "false"
              ) if index > 0
              
              if crumb[:path] && index < breadcrumbs.size - 1
                parts << link_to(crumb[:name], crumb[:path], class: "text-gray-500 hover:text-indigo-600 transition-colors duration-200")
              else
                parts << content_tag(:span, crumb[:name], class: "text-gray-900 font-medium")
              end
              
              safe_join(parts)
            end
          end
        )
      end
    end

    # Return both visual and JSON-LD
    visual_html + content_tag(:script, ERB::Util.json_escape(json_ld.to_json), type: "application/ld+json")
  end
end
