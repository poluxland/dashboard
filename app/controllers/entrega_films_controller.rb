class EntregaFilmsController < ApplicationController
  before_action :set_entrega_film, only: %i[ show edit update destroy ]

  # GET /entrega_films or /entrega_films.json
  def index
    @entrega_films = EntregaFilm.all
  end

  # GET /entrega_films/1 or /entrega_films/1.json
  def show
  end

  # GET /entrega_films/new
  def new
    @entrega_film = EntregaFilm.new
  end

  # GET /entrega_films/1/edit
  def edit
  end

  # POST /entrega_films or /entrega_films.json
  def create
  @entrega_film = EntregaFilm.new(entrega_film_params)

  respond_to do |format|
    if @entrega_film.save
      format.html { redirect_to entrega_films_path, notice: "Entrega de films creada correctamente." }
      format.json { render :show, status: :created, location: @entrega_film }
    else
      format.html { render :new, status: :unprocessable_entity }
      format.json { render json: @entrega_film.errors, status: :unprocessable_entity }
    end
  end
end

# PATCH/PUT /entrega_films/1 or /entrega_films/1.json
def update
  respond_to do |format|
    if @entrega_film.update(entrega_film_params)
      format.html { redirect_to entrega_films_path, notice: "Entrega de films actualizada correctamente.", status: :see_other }
      format.json { render :show, status: :ok, location: @entrega_film }
    else
      format.html { render :edit, status: :unprocessable_entity }
      format.json { render json: @entrega_film.errors, status: :unprocessable_entity }
    end
  end
end

  # DELETE /entrega_films/1 or /entrega_films/1.json
  def destroy
    @entrega_film.destroy!

    respond_to do |format|
      format.html { redirect_to entrega_films_path, notice: "Entrega film was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_entrega_film
      @entrega_film = EntregaFilm.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def entrega_film_params
      params.expect(entrega_film: [ :fecha, :operador_bodega, :rollos_entregados, :observaciones ])
    end
end
