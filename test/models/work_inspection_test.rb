require "test_helper"

class WorkInspectionTest < ActiveSupport::TestCase
  test "all catalog templates snapshot their questions and start without a result" do
    WorkInspection::CATALOG.each do |key, template|
      inspection = works(:one).inspections.create!(template_key: key)
      assert_equal template["items"], inspection.items.map(&:question)
      assert_equal "Sin iniciar", inspection.summary[:state]
      assert_nil inspection.summary[:compliance]
    end
  end

  test "summary excludes not applicable and pending answers and distinguishes partial findings" do
    inspection = works(:one).inspections.create!(template_key: "seguridad")
    inspection.items.first.update!(answer: "no")
    assert_equal "Incompleta", inspection.summary[:state]
    assert_equal 1, inspection.summary[:failed]
    inspection.items.drop(1).each { |item| item.update!(answer: "na") }
    assert_equal "Con hallazgos", inspection.summary[:state]
    assert_equal 0, inspection.summary[:compliance]
    inspection.items.first.update!(answer: "yes")
    assert_equal "Cumple", inspection.summary[:state]
    assert_equal 100, inspection.summary[:compliance]
    inspection.items.first.update!(answer: "na")
    assert_equal "No aplica", inspection.summary[:state]
    assert_nil inspection.summary[:compliance]
  end

  test "invalid answers and question positions are rejected" do
    inspection = works(:one).inspections.create!(template_key: "molino1")
    assert_not inspection.items.first.update(answer: "unknown")
    assert_not inspection.items.build(position: 999, answer: "yes").valid?
    assert_not inspection.update(template_key: "molino2")
  end
end
