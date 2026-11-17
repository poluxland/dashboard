class HaverDashboardController < ApplicationController
  helper EnvasadoraDashboardHelper

  def index
    @report = HaverDashboard.new(params.permit(:week, :month, :ideal))
  rescue HaverDashboard::InvalidFilter, EnvasadoraDashboard::InvalidFilter => error
    flash.now[:alert] = error.message
    @report = HaverDashboard.new
    render :index, status: :unprocessable_entity
  end
end
