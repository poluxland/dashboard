require "open3"

class HaverProductionChart
  PNG_SIGNATURE = "\x89PNG\r\n\x1a\n".b.freeze

  def self.render(days)
    payload = days.map do |day|
      { label: day.fetch(:date).strftime("%d/%m"), tons: day[:tons]&.to_f, rate: day[:rate]&.to_f }
    end
    image, _stderr, status = Open3.capture3(
      ENV.to_h.slice("PATH", "HOME", "LANG"),
      "node", Rails.root.join("script/render_haver_production_chart.cjs").to_s,
      stdin_data: payload.to_json, binmode: true, unsetenv_others: true
    )
    return image if status.success? && image.start_with?(PNG_SIGNATURE)

    Rails.logger.warn("Haver email chart could not be rendered (exit #{status.exitstatus}).")
    nil
  rescue SystemCallError => error
    Rails.logger.warn("Haver email chart renderer unavailable (#{error.class}).")
    nil
  end
end
