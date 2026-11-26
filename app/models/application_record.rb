class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  before_create :record_creator, if: :track_record_author?
  before_update :record_editor, if: :track_record_author?

  private

  def track_record_author?
    RecordAuthor.tracking && has_attribute?(:created_by_email)
  end

  def record_creator
    self.created_by_email = RecordAuthor.email
  end

  def record_editor
    changed_fields = changed_attribute_names_to_save - %w[updated_at created_by_email updated_by_email]
    return if changed_fields.empty? && attachment_changes.empty?

    updated_by_email_will_change!
    self.updated_by_email = RecordAuthor.email
  end
end
