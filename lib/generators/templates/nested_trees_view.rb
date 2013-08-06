class NestedTreesViewTo<%= model_name.pluralize %> < ActiveRecord::Migration
  def up
    execute %(
    CREATE OR REPLACE VIEW view_<%= model_name.tableize %> AS
      SELECT count(<%= model_name.tableize %>.left_key) - 1 AS level,
        <%= (options.key_fields + %w(left_key right_key id)).map do |key|
              %(#{model_name.tableize}.#{key})
            end.join ', '%>
        ( SELECT <%= model_name.tableize %>_parent.post_id
           FROM <%= model_name.tableize %> <%= model_name.tableize %>_parent
          WHERE <%= model_name.tableize %>_parent.left_key < <%= model_name.tableize %>.left_key
            AND <%= model_name.tableize %>_parent.right_key > <%= model_name.tableize %>.right_key
            <%= options.key_fields.map do |key|
              %( AND #{model_name.tableize}.#{key} = #{model_name.tableize}_parent.#{key})
            end.join%>
          ORDER BY <%= model_name.tableize %>.left_key DESC
         LIMIT 1) AS parent
       FROM <%= model_name.tableize %>, <%= model_name.tableize %> <%= model_name.tableize %>_parent
       WHERE <%= model_name.tableize %>.left_key >= <%= model_name.tableize %>_parent.left_key
         AND <%= model_name.tableize %>.left_key <= <%= model_name.tableize %>_parent.right_key
         <%= options.key_fields.map do |key|
            %( AND #{model_name.tableize}.#{key} = #{model_name.tableize}_parent.#{key})
          end.join%>
       GROUP BY
         <%= (options.key_fields + %w(left_key right_key id)).map do |key|
              %(#{model_name.tableize}.#{key})
            end.join ', '%>
       ORDER BY <%= model_name.tableize %>.left_key;
    )
  end
  
  def down
    execute %(DROP VIEW view_<%= model_name.tableize %>;)
  end
end