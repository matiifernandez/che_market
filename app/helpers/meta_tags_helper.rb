module MetaTagsHelper
  def meta_title(title = nil)
    base_title = t("site_name")
    title.present? ? "#{title} | #{base_title}" : base_title
  end

  def meta_description(description = nil)
    description.present? ? description : t("seo.default_description")
  end

  def meta_image(image_url = nil)
    image_url.present? ? image_url : asset_url("og-image.png")
  rescue
    nil
  end

  def meta_tags(title: nil, description: nil, image: nil, type: "website", url: nil)
    title_text = meta_title(title)
    description_text = meta_description(description)
    image_url = meta_image(image)
    canonical_url = url || request.original_url

    # Basic tags
    tags = [
      content_tag(:title, title_text),
      tag(:meta, name: "description", content: description_text),
      tag(:link, rel: "canonical", href: canonical_url)
    ]

    # Helper to generate alternate URLs for different locales, maintaining consistency with canonical_url
    alternate_url_for_locale = lambda do |locale|
      # If an override URL was provided, we use it as the base for alternates
      if url
        begin
          uri = URI.parse(url)
          query_params = Rack::Utils.parse_nested_query(uri.query)
          
          if locale == I18n.default_locale
            query_params.delete("locale")
          else
            query_params["locale"] = locale.to_s
          end
          
          uri.query = query_params.to_query.presence
          uri.to_s
        rescue URI::InvalidURIError
          url_for(locale: (locale == I18n.default_locale ? nil : locale), only_path: false)
        end
      else
        url_for(locale: (locale == I18n.default_locale ? nil : locale), only_path: false)
      end
    end

    # Language alternates
    I18n.available_locales.each do |locale|
      tags << tag(:link, rel: "alternate", hreflang: locale, href: alternate_url_for_locale.call(locale))
    end
    tags << tag(:link, rel: "alternate", hreflang: "x-default", href: alternate_url_for_locale.call(I18n.default_locale))

    # OpenGraph
    tags += [
      tag(:meta, property: "og:title", content: title_text),
      tag(:meta, property: "og:description", content: description_text),
      tag(:meta, property: "og:type", content: type),
      tag(:meta, property: "og:url", content: canonical_url),
      tag(:meta, property: "og:site_name", content: t("site_name")),
      tag(:meta, property: "og:locale", content: I18n.locale == :en ? "en_US" : "es_ES")
    ]
    tags << tag(:meta, property: "og:image", content: image_url) if image_url

    # Twitter
    tags += [
      tag(:meta, name: "twitter:card", content: "summary_large_image"),
      tag(:meta, name: "twitter:title", content: title_text),
      tag(:meta, name: "twitter:description", content: description_text)
    ]
    tags << tag(:meta, name: "twitter:image", content: image_url) if image_url

    safe_join(tags)
  end
end
