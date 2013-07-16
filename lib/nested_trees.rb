module NestedTrees
  def nested_trees_before_create
    max = (self.class.maximum(nested_trees_options[:right_key], :conditions => __nested_key_conditions) || 0) + 1
    self[nested_trees_options[:left_key]] = max
    self[nested_trees_options[:right_key]] = max + 1
  end
  
  ###
  # = Options
  # * +:parent+ - parent node
  # * +:prev+ - previous node
  ###
  def nested_move(options = {})
    unless nested_trees_options[:with_key].nil? then
      target = options[:parent] || options[:prev]
      return if target[nested_trees_options[:with_key]] != self[nested_trees_options[:with_key]] and !target.nil?
    end
    
    if !options[:parent].nil? and options[:prev].nil? then 
      __nested_move_node :target => options[:parent], :direction => :child
    elsif !options[:prev].nil? then
      __nested_move_node :target => options[:prev], :direction => :right
    else
      __nested_move_node :target => nil, :direction => :left
    end
    reload
  end
  
  private
    def __nested_move_node(options = {})
      transaction do
        size = 0
        dif = 0
        target, lk, rk = options[:target], nested_trees_options[:left_key], nested_trees_options[:right_key]
        bs, bo = {:left => self[lk], :right => self[rk]}, {:left => nil, :right => nil} # between self, between other
        
        case options[:direction]
        when :right
          if target[lk] < self[lk] then
            size = self[rk] - self[lk] + 1
            if target[rk] < self[lk] then
              dif = self[lk] - target[rk] - 1
              bo = {:left => target[rk] + 1, :right => self[lk] - 1}
            else
              dif = self[rk] - target[rk]
              size = -size
              bo = {:left => self[rk] + 1, :right => target[rk]}
            end
          else
            size = self[lk] - self[rk] - 1
            if target[rk] > self[rk] then
              dif = self[rk] - target[rk]
              bo = {:left => self[rk] + 1, :right => target[rk]}
            else
              dif = self[lk] - target[lk]
              bo = {:left => target[rk], :right => self[rk] + 1}
            end
          end
        when :left
          size = self[rk] - self[lk] + 1
          dif = self[lk] - 1
          bo = {:left => 1, :right => self[lk] - 1}
        when :child # v0.0.1 test NOT completed
          if target[lk] > self[lk]
            size = self[lk] - self[rk] - 1
            dif = self[rk] - target[lk] # dif ok
            bo = {:left => self[rk] + 1, :right => target[lk]}
          else
            size = self[rk] - self[lk] + 1
            dif = self[lk] - target[lk] - 1 # dif of
            bo = {:left => target[lk] + 1, :right => self[rk]}
          end
        end
        
        self.class.update_all [%(
          #{__qlk} = CASE
            WHEN #{__qlk} BETWEEN :bsl AND :bsr
              THEN #{__qlk} - :dif
            WHEN #{__qlk} BETWEEN :bol AND :bor
              THEN #{__qlk} + :size
            ELSE #{__qlk} END,
          #{__qrk} = CASE
            WHEN #{__qrk} BETWEEN :bsl AND :bsr
              THEN #{__qrk} - :dif
            WHEN #{__qrk} BETWEEN :bol AND :bor
              THEN #{__qrk} + :size
            ELSE #{__qrk} END
        ), {
          :bsl => bs[:left], :bsr => bs[:right],
          :bol => bo[:left], :bor => bo[:right],
          :dif => dif, :size => size}], __nested_key_conditions
      end
      options[:target].reload unless options[:target].nil?
    end
    
    def __quoted_left_key
      connection.quote_column_name nested_trees_options[:left_key]
    end
    
    def __quoted_right_key
      connection.quote_column_name nested_trees_options[:right_key]
    end
    
    def __nested_key_conditions
      return '1=1' if nested_trees_options[:with_key].nil?
      {nested_trees_options[:with_key].intern => self[nested_trees_options[:with_key]]}
    end
    
    alias_method :__qlk, :__quoted_left_key
    alias_method :__qrk, :__quoted_right_key
end

class ActiveRecord::Base
  def self.nested_trees(options = {})
    cattr_accessor :nested_trees_options
    
    include NestedTrees
    
    self.nested_trees_options = {
      :left_key => :left_key,
      :right_key => :right_key,
      :with_key => nil
    }.merge options
    
    before_create :nested_trees_before_create
  end
end