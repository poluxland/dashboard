class EnvasadoraDashboardController < ApplicationController
  def index
    @dashboard = EnvasadoraDashboard.new(filter_params, default_source: "haver").call
    @pagy, @detail_rows = pagy_array(@dashboard.rows, limit: 60)
  rescue EnvasadoraDashboard::InvalidFilter => error
    flash.now[:alert] = error.message
    @dashboard = EnvasadoraDashboard.new({}, default_source: "haver").call
    @pagy, @detail_rows = pagy_array(@dashboard.rows, limit: 60)
    render :index, status: :unprocessable_entity
  end

  private

  def filter_params
    params.permit(:from, :to, :period, :pareto, :top, :exclude_unscheduled, :include_missing_reason, shifts: [], weekdays: []).to_h
  end
end
