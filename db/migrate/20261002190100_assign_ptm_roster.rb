class AssignPtmRoster < ActiveRecord::Migration[8.1]
  class PersonRecord < ActiveRecord::Base
    self.table_name = "people"
  end

  ROSTER = {
    "Adicionales PTM" => [ "Héctor Ampuero", "Miguel Levin", "Pablo Calisto", "Jaime Lopez" ],
    "Electrico PTM" => [ "Luis Nava", "Pedro Aristigueta", "Armando Miranda" ],
    "Mecanica PTM" => [ "Pedro Pichaud", "Erwin Carrasco", "Cristian Barra", "Celso Aniñir", "Mauricio Catalan" ],
    "Operaciones PTM" => [ "Víctor Gallardo", "Hans Velasquez", "Emilio Gomez", "Jonny Roa", "Cristian Ramirez", "Jose Aro", "Jose Diaz", "Javier Cárcamo", "Bayron Gallardo", "Luis Muñoz", "Cristobal Vargas", "Yonathan Vargas", "Nibaldo Muñoz", "Nelson Queupuan", "Matias Vargas", "Samuel Muñoz", "Daniel Cifuentes" ],
    "Envasado PTM" => [ "Exequiel Moya", "Victor Soto", "Mateo Andrade", "Rodrigo Campos", "Paul Pierre", "Juan Gallardo", "Gabriel Soto", "Luis Ñanco", "Benedicto Alvear", "Claudio Marquez", "Mauricio Huenchiñir", "Isaias Ojeda", "Maria Raipane", "Luis Gonzalez", "Evaldo Tauda" ]
  }.freeze

  def up
    PersonRecord.reset_column_information
    ROSTER.each do |area, names|
      names.each do |name|
        matches = PersonRecord.all.select { |person| normalized(person.name) == normalized(name) }
        raise "Nombre ambiguo en nómina: #{name}" if matches.size > 1

        person = matches.first || PersonRecord.new(name: name, indicator_enabled: false)
        person.update!(area: area, planta: "PTM")
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "La nómina conserva personas e indicadores existentes."
  end

  private

  def normalized(name)
    ActiveSupport::Inflector.transliterate(name.to_s).downcase.squish
  end
end
