require "test_helper"

class OperationActivitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_with_google
  end

  test "registra y modifica una actividad con avance parcial" do
    get new_operation_activity_path
    assert_response :success
    assert_select "select[name='operation_activity[area]'] option[value]:not([value=''])", 12
    assert_select "input[type=file]", 0

    post operation_activities_path, params: { operation_activity: activity_attributes }
    assert_redirected_to operation_activities_path(semana: "2026-05-19")
    record = OperationActivity.find_by!(actividad: "Recuperación de material")
    assert_equal 80.25, record.estado

    get edit_operation_activity_path(record)
    assert_response :success
    patch operation_activity_path(record), params: { operation_activity: { estado: 100 } }
    assert_redirected_to operation_activities_path(semana: "2026-05-19")
    assert_equal 100, record.reload.estado
  end

  test "rechaza áreas y tipos fuera del catálogo y porcentajes fuera de rango" do
    assert_no_difference "OperationActivity.count" do
      post operation_activities_path, params: {
        operation_activity: activity_attributes.merge(area: "Área libre", tipo: "Urgente", estado: 101)
      }
    end
    assert_response :unprocessable_entity
    assert_select "[role=alert] li", 3
  end

  test "el informe incluye el lunes y domingo aun cuando la semana cruza el año" do
    OperationActivity.create!(activity_attributes.merge(fecha: "2026-12-28", estado: 0))
    OperationActivity.create!(activity_attributes.merge(fecha: "2027-01-03", tipo: "Contingencia", estado: 100, actividad: "Limpieza de cinta"))
    OperationActivity.create!(activity_attributes.merge(fecha: "2027-01-04", actividad: "Registro de la semana siguiente"))

    get operation_activities_path, params: { semana: "2027-01-01" }
    assert_response :success
    assert_select "h1", text: "Informe semanal de operaciones · Semana 53"
    assert_select ".card-body .fw-bold", text: "50 %"
    assert_select "tbody tr", 2
    assert_select "tbody", text: /Limpieza de cinta/
    assert_select "tbody", text: /Registro de la semana siguiente/, count: 0
  end

  private

  def activity_attributes
    { fecha: "2026-05-19", area: "Molino PTM-1", actividad: "Recuperación de material", tipo: "Programada", estado: 80.25 }
  end
end
