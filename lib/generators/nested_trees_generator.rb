class NestedTreesGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  
  desc 'Generate migration view for model'
  argument :model_name, :type => :string
  class_option :key_fields, :type => :array, :default => [], :desc => 'additional nested key'
  source_root File.expand_path('../templates', __FILE__)
  
  def self.next_migration_number(dirname)
    Time.now.utc.strftime("%Y%m%d%H%M%S")
  end
  
  def create_migration_file
    migration_template 'nested_trees_view.rb', %(db/migrate/nested_trees_view_to_#{model_name.tableize}.rb)
  end
end