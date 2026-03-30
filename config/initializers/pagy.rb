# frozen_string_literal: true

require 'pagy'

# Pagy configuration
# See https://ddnexus.github.io/pagy/toolbox/configuration/initializer/

# Global options
Pagy::OPTIONS[:limit] = 12 # Items per page
Pagy::OPTIONS[:size] = 7   # Nav bar links
