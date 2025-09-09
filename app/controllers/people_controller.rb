# app/controllers/people_controller.rb
class PeopleController < ApplicationController
  before_action :set_person, only: [ :show, :edit, :update, :destroy ]

  def index
    @people = Person.order(:name)
  end

  def show; end

  def new
    @person = Person.new
  end

  def create
    @person = Person.new(person_params)
    if @person.save
      redirect_to people_path, notice: "Persona creada."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @person.update(person_params)
      redirect_to people_path, notice: "Persona actualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @person.destroy
    redirect_to people_path, notice: "Persona eliminada."
  end

  private

  def set_person
    @person = Person.find(params[:id])
  end

  def person_params
    # incluye :planta
    params.require(:person).permit(:name, :planta)
  end
end
