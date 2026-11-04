require "test_helper"

class WorkTest < ActiveSupport::TestCase
  test "new reports default to today's date in Chile and allow a different date" do
    travel_to Time.utc(2026, 11, 3, 1, 0, 0) do
      assert_equal Date.new(2026, 11, 2), Work.new.fecha
      assert_equal Date.new(2026, 10, 1), Work.new(fecha: "2026-10-01").fecha
      work = works(:one)
      work.update!(fecha: "2026-10-01")
      assert_equal Date.new(2026, 10, 1), work.reload.fecha
    end
  end

  test "validates file type and size in all photo groups" do
    %i[fotos fotos_antes fotos_despues].each do |field|
      work = Work.new
      blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("invalid"), filename: "invalid.txt", content_type: "text/plain")
      blob.update!(byte_size: 11.megabytes)
      work.public_send(field).attach(blob)
      assert_not work.valid?
      assert_includes work.errors[field], "deben ser PNG/JPG/JPEG/WEBP"
      assert_includes work.errors[field], "cada imagen debe pesar menos de 10MB"
    end
  end
end
