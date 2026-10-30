# config/initializers/pagy.rb
require "pagy"                    # por si alguna vez usaste require: false
require "pagy/extras/bootstrap"   # habilita pagy_bootstrap_nav
# Opcional:
# Pagy::DEFAULT[:items] = 20
# Paginate the merged production/TPT detail after applying shared filters.
require "pagy/extras/array"
