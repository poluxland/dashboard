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
  GLOBAL_EXTERNAL_REVIEWERS = %w[joseignaciojerez@gmail.com].freeze
  RECIPIENTS = (STAFF + EXTERNAL.keys).freeze

  def self.normalize(email)
    email.to_s.strip.downcase
  end

  def self.staff?(email)
    STAFF.include?(normalize(email))
  end

  def self.external?(email)
    normalized = normalize(email)
    EXTERNAL.key?(normalized) || GLOBAL_EXTERNAL_REVIEWERS.include?(normalized)
  end

  def self.global_reviewer?(email)
    staff?(email) || GLOBAL_EXTERNAL_REVIEWERS.include?(normalize(email))
  end

  def self.entries_for(email)
    return OvertimeEntry.all if global_reviewer?(email)

    mandante = EXTERNAL[normalize(email)]
    mandante ? OvertimeEntry.where(mandante: mandante) : OvertimeEntry.none
  end
end
