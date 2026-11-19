class EstadoCanchaMailer < ApplicationMailer
  def self.recipients
    ENV.fetch("ESTADO_CANCHAS_REPORT_RECIPIENTS", "").split(/[\s,;]+/).compact_blank.uniq
  end

  def status(record)
    @estado_cancha = record
    @timestamp = record.local_timestamp.strftime("%d/%m/%Y %H:%M")
    mail(to: self.class.recipients, subject: "Estado de canchas - #{@timestamp}")
  end
end
