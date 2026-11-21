module OvertimeAccess
  STAFF = %w[
    camila.birke@msindustrial.cl
    julio.alvear@msindustrial.cl
    fernando.gonzalez@msindustrial.cl
    jose.jerez@msindustrial.cl
  ].freeze
  EXTERNAL = {
    "martin.llancafil@meloncementos.cl" => "Martin Llancafil",
    "daniel.garrido@meloncementos.cl" => "Daniel Garrido",
    "johnny.rute@meloncementos.cl" => "Johnny Rute",
    "carolina.vera@meloncementos.cl" => "Carolina Vera"
  }.freeze
  RECIPIENTS = (STAFF + EXTERNAL.keys).freeze

  def self.normalize(email)
    email.to_s.strip.downcase
  end

  def self.staff?(email)
    STAFF.include?(normalize(email))
  end

  def self.external?(email)
    EXTERNAL.key?(normalize(email))
  end

  def self.entries_for(email)
    return OvertimeEntry.all if staff?(email)

    mandante = EXTERNAL[normalize(email)]
    mandante ? OvertimeEntry.where(mandante: mandante) : OvertimeEntry.none
  end
end
