module MetaTagsHelper
  def meta_title(title = nil)
    base_title = t("site_name")
    title.present? ? "#{title} | #{base_title}" : base_title
  end

  def meta_description(description = nil)
    description || t("seo.default_description")
  end

  def meta_image(image_url = nil)
    image_url || asset_url("og-image.png")
  rescue
    nil
  end

  def meta_tags(title: nil, description: nil, image: nil, type: "website", url: nil)
    title_text = meta_title(title)
    description_text = meta_description(description)
    image_url = meta_image(image)
    canonical_url = url || request.original_url

    content_tag(:title, title_text) +
    tag(:meta, name: "description", content: description_text) +
    tag(:meta, property: "og:title", content: title_text) +
    tag(:meta, property: "og:description", content: description_text) +
    tag(:meta, property: "og:type", content: type) +
    tag(:meta, property: "og:url", content: canonical_url) +
    tag(:meta, property: "og:site_name", content: t("site_name")) +
    (image_url ? tag(:meta, property: "og:image", content: image_url) : "") +
    tag(:meta, name: "twitter:card", content: "summary_large_image") +
    tag(:meta, name: "twitter:title", content: title_text) +
    tag(:meta, name: "twitter:description", content: description_text) +
    (image_url ? tag(:meta, name: "twitter:image", content: image_url) : "") +
    tag(:link, rel: "canonical", href: canonical_url)
  end
end
