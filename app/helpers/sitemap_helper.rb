module SitemapHelper
  def sitemap_alternate_links(url_base_method, *args)
    options = args.extract_options!
    
    links = I18n.available_locales.map do |locale|
      locale_param = (locale == I18n.default_locale ? nil : locale)
      url = send(url_base_method, *args, options.merge(locale: locale_param, only_path: false))
      
      { hreflang: locale, href: url }
    end

    # Add x-default
    default_url = send(url_base_method, *args, options.merge(locale: nil, only_path: false))
    links << { hreflang: "x-default", href: default_url }
    
    links
  end

  # Helper for manual URLs (like root_url)
  def sitemap_alternate_links_for_path(path_helper, *args)
    sitemap_alternate_links(path_helper, *args)
  end
end
