class NestedTreesViewTo<%= model_name.pluralize %> < ActiveRecord::Migration
  def up
    execute %(
    CREATE OR REPLACE VIEW view_<%= model_name.pluralize %> AS
      SELECT count(<%= model_name.pluralize %>.left_key) - 1 AS level,
        <%= (options.key_fields + %w(left_key right_key id)).map do |key|
              %(#{model_name.pluralize}.#{key})
            end.join ','%>
        ( SELECT <%= model_name.pluralize %>_parent.post_id
           FROM <%= model_name.pluralize %> <%= model_name.pluralize %>_parent
          WHERE <%= model_name.pluralize %>_parent.left_key < <%= model_name.pluralize %>.left_key
            AND <%= model_name.pluralize %>_parent.right_key > <%= model_name.pluralize %>.right_key
            <%= options.key_fields.map do |key|
              %( AND #{model_name.pluralize}.#{key} = #{model_name.pluralize}_parent.#{key})
            end.join%>
          ORDER BY <%= model_name.pluralize %>.left_key DESC
         LIMIT 1) AS parent
       FROM <%= model_name.pluralize %>, <%= model_name.pluralize %> <%= model_name.pluralize %>_parent
       WHERE <%= model_name.pluralize %>.left_key >= <%= model_name.pluralize %>_parent.left_key
         AND <%= model_name.pluralize %>.left_key <= <%= model_name.pluralize %>_parent.right_key
         <%= options.key_fields.map do |key|
            %( AND #{model_name.pluralize}.#{key} = #{model_name.pluralize}_parent.#{key})
          end.join%>
       GROUP BY
         <%= (options.key_fields + %w(left_key right_key id)).map do |key|
              %(#{model_name.pluralize}.#{key})
            end.join ','%>
       ORDER BY <%= model_name.pluralize %>.left_key;
    )
  end
  
  def down
    execute %(DROP VIEW view_<%= model_name.pluralize %>;)
  end
end