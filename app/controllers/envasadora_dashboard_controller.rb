class EnvasadoraDashboardController < ApplicationController
  SHIFT_STARTS = { "TM" => 6, "TT" => 14, "TN" => 22 }.freeze

  def index
    @dashboard = EnvasadoraDashboard.new(filter_params, shift_starts: SHIFT_STARTS, default_source: "haver").call
    @pagy, @detail_rows = pagy_array(@dashboard.rows, limit: 60)
  rescue EnvasadoraDashboard::InvalidFilter => error
    flash.now[:alert] = error.message
    @dashboard = EnvasadoraDashboard.new({}, shift_starts: SHIFT_STARTS, default_source: "haver").call
    @pagy, @detail_rows = pagy_array(@dashboard.rows, limit: 60)
    render :index, status: :unprocessable_entity
  end

  private

  def filter_params
    params.permit(:from, :to, :period, :pareto, :top, :exclude_unscheduled, shifts: [], weekdays: []).to_h
  end
end
