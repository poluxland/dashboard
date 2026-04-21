class Enfundado < ApplicationRecord
  TURNOS = ["Turno Mañana", "Turno Tarde", "Turno Noche"].freeze

  validates :operador, :fecha, :turno, presence: true
  validates :turno, inclusion: { in: TURNOS }
  validates :turno, uniqueness: {
    scope: :fecha,
    message: "ya fue registrado para esta fecha"
  }

  PESOS_MANUAL = {
    especial_plastificados_lados: 207,
    especial_plastificados_completo: 366,
    especial_plastificados_3_vueltas: 245,
    especial_plastificado_zuncho_reforzado: 366,
    especial_plastificado_completo_doble_films: 366,
    especial_soluble_plastificados_completo: 366,
    extra_plastificados_lados: 207,
    extra_plastificados_completo_doble_films: 366,
    extra_plastificados_completo_doble_films_zuncho: 366,
    extra_soluble_plastificados_completo: 366
  }.freeze

  PESOS_AUTOMATICA = {
    especial_plastificados_lados: 360,
    especial_plastificados_completo: 510,
    especial_plastificados_3_vueltas: 0,
    especial_plastificado_zuncho_reforzado: 510,
    especial_plastificado_completo_doble_films: 510,
    especial_soluble_plastificados_completo: 510,
    extra_plastificados_lados: 360,
    extra_plastificados_completo_doble_films: 510,
    extra_plastificados_completo_doble_films_zuncho: 510,
    extra_soluble_plastificados_completo: 510
  }.freeze

  def total_manual_reporte
    numero_pallet_enfundado_manual.to_i +
      especial_plastificados_lados_manual.to_i +
      especial_plastificados_completo_manual.to_i +
      especial_plastificados_3_vueltas_manual.to_i +
      especial_plastificado_zuncho_reforzado_manual.to_i +
      especial_plastificado_completo_doble_films_manual.to_i +
      especial_soluble_plastificados_completo_manual.to_i +
      extra_plastificados_lados_manual.to_i +
      extra_plastificados_completo_doble_films_manual.to_i +
      extra_plastificados_completo_doble_films_zuncho_manual.to_i +
      extra_soluble_plastificados_completo_manual.to_i
  end

  def total_automatica_reporte
    numero_pallet_enfundado_automatica.to_i +
      especial_plastificados_lados_automatica.to_i +
      especial_plastificados_completo_automatica.to_i +
      especial_plastificados_3_vueltas_automatica.to_i +
      especial_plastificado_zuncho_reforzado_automatica.to_i +
      especial_plastificado_completo_doble_films_automatica.to_i +
      especial_soluble_plastificados_completo_automatica.to_i +
      extra_plastificados_lados_automatica.to_i +
      extra_plastificados_completo_doble_films_automatica.to_i +
      extra_plastificados_completo_doble_films_zuncho_automatica.to_i +
      extra_soluble_plastificados_completo_automatica.to_i
  end

  def gramos_consumidos_manual
    PESOS_MANUAL.sum do |campo, gramos|
      cantidad = public_send("#{campo}_manual").to_i
      cantidad * gramos
    end
  end

  def gramos_consumidos_automatica
    PESOS_AUTOMATICA.sum do |campo, gramos|
      cantidad = public_send("#{campo}_automatica").to_i
      cantidad * gramos
    end
  end

  def gramos_consumidos_total
    gramos_consumidos_manual + gramos_consumidos_automatica
  end
end