module StructuredDataHelper
  def product_json_ld(product)
    # Basic product info
    data = {
      "@context": "https://schema.org/",
      "@type": "Product",
      "name": product.name,
      "description": strip_tags(product.description.to_s).strip,
      "sku": "SKU-#{product.id}",
      "brand": {
        "@type": "Brand",
        "name": t("site_name")
      }
    }

    # Images
    if product.images.attached?
      data[:image] = product.images.map { |img| url_for(img) }
    end

    # Offers (Pricing and Availability)
    data[:offers] = {
      "@type": "Offer",
      "url": product_url(product),
      "priceCurrency": product.price.currency.iso_code,
      "price": product.price.amount.to_s("F"),
      "availability": product.stock > 0 ? "https://schema.org/InStock" : "https://schema.org/OutOfStock",
      "itemCondition": "https://schema.org/NewCondition"
    }

    # Aggregate Rating
    if product.reviews_count > 0
      data[:aggregateRating] = {
        "@type": "AggregateRating",
        "ratingValue": product.average_rating,
        "reviewCount": product.reviews_count,
        "bestRating": "5",
        "worstRating": "1"
      }

      # Individual Reviews (show top 5 recent)
      data[:review] = product.visible_reviews.includes(:user).limit(5).map do |review|
        {
          "@type": "Review",
          "reviewRating": {
            "@type": "Rating",
            "ratingValue": review.rating,
            "bestRating": "5",
            "worstRating": "1"
          },
          "author": {
            "@type": "Person",
            "name": review.user.first_name.presence || "User"
          },
          "datePublished": review.created_at.strftime("%Y-%m-%d"),
          "reviewBody": review.body,
          "name": review.title.presence || product.name
        }
      end
    end

    # Return as safe JSON script tag
    content_tag :script, type: "application/ld+json" do
      ERB::Util.json_escape(data.to_json).html_safe
    end
  end
end
