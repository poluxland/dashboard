class ShiftReport < ApplicationRecord
  STATEMENT = "Por medio del presente informe, se deja constancia de que las personas individualizadas en la nómina adjunta finalizaron su turno sin novedades reportadas de carácter laboral ni situaciones anormales. Al cierre de la jornada, no se informaron malestares físicos, golpes, lesiones, accidentes ni otros incidentes que afectaran su bienestar o el normal desarrollo de sus funciones. Esta declaración corresponde a la información recabada al término del turno indicado.".freeze
  RECIPIENTS = %w[
    jose.jerez@msindustrial.cl
    fernando.gonzalez@msindustrial.cl
    julio.alvear@msindustrial.cl
    martin.llancafil@meloncementos.cl
    gari.aguilera@meloncementos.cl
    johnny.rute@meloncementos.cl
    mario.diaz@meloncementos.cl
    helmut.brandau@meloncementos.cl
    carolina.vera@meloncementos.cl
  ].freeze

  attr_accessor :person_ids, :confirmed
  validates :date, :shift, :signer_name, :signer_email, :statement, presence: true
  validates :participants, presence: { message: "debe incluir al menos una persona" }
  validates :confirmed, acceptance: { accept: "1", allow_nil: false, message: "debe confirmar el cierre sin novedades" }, on: :create
end
