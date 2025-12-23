# frozen_string_literal: true

require 'pagy'

# Pagy configuration
# See https://ddnexus.github.io/pagy/docs/api/pagy#variables

# Instance variables
Pagy::DEFAULT[:items] = 12  # Items per page
Pagy::DEFAULT[:size]  = 7   # Nav bar links

# Overflow handling - redirect to last page instead of raising error
require 'pagy/extras/overflow'
Pagy::DEFAULT[:overflow] = :last_page
