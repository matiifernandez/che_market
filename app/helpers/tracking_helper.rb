module TrackingHelper
  # Common carriers with their tracking URL patterns
  # The {tracking_number} placeholder will be replaced with the actual tracking number
  CARRIERS = {
    "fedex" => {
      name: "FedEx",
      url: "https://www.fedex.com/fedextrack/?trknbr={tracking_number}"
    },
    "ups" => {
      name: "UPS",
      url: "https://www.ups.com/track?tracknum={tracking_number}"
    },
    "dhl" => {
      name: "DHL",
      url: "https://www.dhl.com/en/express/tracking.html?AWB={tracking_number}"
    },
    "usps" => {
      name: "USPS",
      url: "https://tools.usps.com/go/TrackConfirmAction?tLabels={tracking_number}"
    },
    "correo_argentino" => {
      name: "Correo Argentino",
      url: "https://www.correoargentino.com.ar/formularios/e-carta?id={tracking_number}"
    },
    "oca" => {
      name: "OCA",
      url: "https://www.oca.com.ar/Envios/seguimiento?numero={tracking_number}"
    },
    "andreani" => {
      name: "Andreani",
      url: "https://www.andreani.com/#!/tracking/{tracking_number}"
    },
    "other" => {
      name: "Otro",
      url: nil
    }
  }.freeze

  # Get list of carriers for select dropdown
  def carrier_options_for_select
    CARRIERS.map { |key, data| [data[:name], key] }
  end

  # Get carrier display name
  def carrier_name(carrier_key)
    CARRIERS.dig(carrier_key, :name) || carrier_key&.humanize || "Desconocido"
  end

  # Build tracking URL for a given carrier and tracking number
  def tracking_url(carrier_key, tracking_number)
    return nil if tracking_number.blank?

    url_template = CARRIERS.dig(carrier_key, :url)
    return nil if url_template.nil?

    url_template.gsub("{tracking_number}", tracking_number)
  end

  # Render a tracking link or just the number if no URL available
  def tracking_link(carrier_key, tracking_number, options = {})
    return nil if tracking_number.blank?

    url = tracking_url(carrier_key, tracking_number)
    link_class = options[:class] || "text-indigo-600 hover:text-indigo-800"

    if url.present?
      link_to tracking_number, url, target: "_blank", rel: "noopener noreferrer", class: link_class
    else
      content_tag(:span, tracking_number, class: "font-mono")
    end
  end
end
