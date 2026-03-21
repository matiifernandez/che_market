module SitemapHelper
  def sitemap_xhtml_links(url_base_method, route_args = nil, options = {})
    html = ""
    I18n.available_locales.each do |locale|
      locale_param = (locale == I18n.default_locale ? nil : locale)
      url_options = options.merge(locale: locale_param, only_path: false)
      
      url = if route_args
              send(url_base_method, route_args, url_options)
            else
              send(url_base_method, url_options)
            end
      
      html << "<xhtml:link rel=\"alternate\" hreflang=\"#{locale}\" href=\"#{url}\" />\n    "
    end

    # x-default
    default_url = if route_args
                    send(url_base_method, route_args, options.merge(locale: nil, only_path: false))
                  else
                    send(url_base_method, options.merge(locale: nil, only_path: false))
                  end
    
    html << "<xhtml:link rel=\"alternate\" hreflang=\"x-default\" href=\"#{default_url}\" />"
    
    html.html_safe
  end
end
