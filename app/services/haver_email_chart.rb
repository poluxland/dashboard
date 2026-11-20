require "open3"

class HaverEmailChart
  PNG_SIGNATURE = "\x89PNG\r\n\x1a\n".b.freeze

  def self.production(days)
    payload = days.map do |day|
      { label: day.fetch(:date).strftime("%d/%m"), tons: day[:tons]&.to_f, rate: day[:rate]&.to_f }
    end
    render("production", payload)
  end

  def self.pareto(causes)
    render("pareto", causes.map { |cause| cause.slice(:label, :minutes, :cumulative) })
  end

  def self.render(kind, rows)
    return if rows.empty?

    image, _stderr, status = Open3.capture3(
      ENV.to_h.slice("PATH", "HOME", "LANG"),
      "node", Rails.root.join("script/render_haver_email_chart.cjs").to_s,
      stdin_data: { kind: kind, rows: rows }.to_json, binmode: true, unsetenv_others: true
    )
    return image if status.success? && image.start_with?(PNG_SIGNATURE)

    Rails.logger.warn("Haver email #{kind} chart could not be rendered (exit #{status.exitstatus}).")
    nil
  rescue SystemCallError => error
    Rails.logger.warn("Haver email #{kind} chart renderer unavailable (#{error.class}).")
    nil
  end
  private_class_method :render
end
