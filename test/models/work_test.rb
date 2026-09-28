require "test_helper"

class WorkTest < ActiveSupport::TestCase
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
