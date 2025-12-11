# frozen_string_literal: true

SimpleForm.setup do |config|
  # Wrappers for Tailwind CSS
  config.wrappers :default, class: "mb-4" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: "block text-sm font-medium text-gray-700 mb-1"
    b.use :input, class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500", error_class: "border-red-500"
    b.use :full_error, wrap_with: { tag: :p, class: "mt-1 text-sm text-red-600" }
    b.use :hint, wrap_with: { tag: :p, class: "mt-1 text-sm text-gray-500" }
  end

  # Default configuration
  config.default_wrapper = :default
  config.boolean_style = :inline
  config.button_class = "px-4 py-2 bg-indigo-600 text-white font-medium rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
  config.generate_additional_classes_for = []
  config.browser_validations = false
  config.label_text = lambda { |label, required, explicit_label| "#{label}" }
  config.error_notification_tag = :div
  config.error_notification_class = "p-4 mb-4 bg-red-100 border border-red-400 text-red-700 rounded"
end
