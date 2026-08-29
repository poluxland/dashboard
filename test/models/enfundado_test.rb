require "test_helper"

class EnfundadoTest < ActiveSupport::TestCase
  test "films usados incluye manual automatica y tapa" do
    enfundado = Enfundado.new(
      numero_rollos_films_cambiados_manual: 2,
      numero_rollos_films_cambiados_automatica: 3,
      numero_rollos_films_tapa: 4
    )

    assert_equal 2, enfundado.films_usados_manual
    assert_equal 3, enfundado.films_usados_automatica
    assert_equal 4, enfundado.films_usados_tapa
    assert_equal 9, enfundado.films_usados_total
  end
end
