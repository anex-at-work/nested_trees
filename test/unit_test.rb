require 'test/unit'
require 'active_record'
require 'logger'

require 'nested_trees'


class UnitTest < Test::Unit::TestCase
  def initialize(*args)
    super
    
    db_file = File.join(File.dirname(__FILE__), 'db_test.sqlite')
    File.new db_file, 'w'
    ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => db_file
    ActiveRecord::Base.connection.execute %(
      CREATE TABLE IF NOT EXISTS nested_sets(
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        key_value INTEGER DEFAULT '',
        left_key INTEGER NOT NULL,
        right_key INTEGER NOT NULL
      );
    )
    ActiveRecord::Base.connection.execute %(
      CREATE TABLE IF NOT EXISTS nested_with_keys(
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        key_value INTEGER NOT NULL,
        value INTEGER DEFAULT '',
        left_key INTEGER NOT NULL,
        right_key INTEGER NOT NULL
      );
    )
    #ActiveRecord::Base.logger = Logger.new(STDOUT)
  end
 
  def test_default_options
    assert_not_nil NestedSet::nested_trees_options
    assert_equal NestedSet::nested_trees_options[:left_key], :left_key
    assert_equal NestedSet::nested_trees_options[:right_key], :right_key
  end  

  def test_create_objects_at_root
    obj = NestedSet.create :key_value => 1
    assert_not_nil obj
    assert_equal 1, obj.left_key
    assert_equal 2, obj.right_key
    
    20.times do |i| 
      obj = NestedSet.create :key_value => i + 2
      assert_equal (i + 2)*2 -1, obj.left_key
      assert_equal (i + 2)*2, obj.right_key
    end
  end
  
  # 
  # Create two objects and move object with value "2" as child of the object with value "1"
  # Must be:
  # * 1   4
  # *  2 3
  # 
  def test_create_and_move_as_child
    obj = NestedSet.create :key_value => 1
    assert_not_nil obj
    
    obj_child = NestedSet.create :key_value => 2
    obj_child.nested_move :parent => obj
    assert_equal obj_child.left_key, 2
    assert_equal obj_child.right_key, 3
    assert_equal obj.left_key, 1
    assert_equal obj.right_key, 4
  end
  
  def test_move_together
    obj_1 = NestedSet.create :key_value => 1
    obj_2 = NestedSet.create :key_value => 2
    
    assert_equal 3, obj_2.left_key
    obj_1.nested_move :prev => obj_2
    assert_equal 1, obj_2.left_key
    assert_equal 2, obj_2.right_key
    assert_equal 3, obj_1.left_key
    assert_equal 4, obj_1.right_key
    
    obj_1.nested_move # move to first position
    assert_equal 1, obj_1.left_key
    assert_equal 2, obj_1.right_key
    obj_2.reload
    assert_equal 3, obj_2.left_key
    assert_equal 4, obj_2.right_key
  end 
  
  def test_move_threesome
    obj_1 = NestedSet.create :key_value => 1
    obj_2 = NestedSet.create :key_value => 2
    obj_3 = NestedSet.create :key_value => 3
    assert_equal 5, obj_3.left_key
    
    # state:
    # obj_1
    # obj_3
    # obj_2
    obj_3.nested_move :prev => obj_1
    obj_2.reload
    assert_equal 5, obj_2.left_key
    assert_equal 3, obj_3.left_key
    
    # state:
    # obj_1  1  2
    # obj_2  3  6
    #   obj_3  4  5
    obj_3.nested_move :parent => obj_2
    assert_equal 1, obj_1.left_key
    assert_equal 3, obj_2.left_key
    assert_equal 6, obj_2.right_key
    assert_equal 4, obj_3.left_key
    assert_equal 5, obj_3.right_key
    
    # state
    # obj_2  1  6
    #   obj_3  2  5
    #     obj_1  3  4
    obj_1.nested_move :parent => obj_3
    obj_2.reload
    assert_equal 3, obj_1.left_key
    assert_equal 4, obj_1.right_key
    assert_equal 1, obj_2.left_key
    assert_equal 6, obj_2.right_key
    assert_equal 2, obj_3.left_key
    assert_equal 5, obj_3.right_key
    
    # state 
    # obj_2  1  6
    #   obj_1  2  3
    #   obj_3  4  5
    obj_1.nested_move :parent => obj_2
    obj_3.reload
    assert_equal 2, obj_1.left_key
    assert_equal 3, obj_1.right_key
    assert_equal 1, obj_2.left_key
    assert_equal 6, obj_2.right_key
    assert_equal 4, obj_3.left_key
    assert_equal 5, obj_3.right_key
  end

  def test_move_foursome
    obj_1 = NestedSet.create :key_value => 1
    obj_2 = NestedSet.create :key_value => 2
    obj_3 = NestedSet.create :key_value => 3
    obj_4 = NestedSet.create :key_value => 4
    assert_equal 8, obj_4.right_key
    
    # state
    # obj_1      1  8
    #   obj_2      2  3
    #   obj_4      4  7
    #     obj_3      5  6
    obj_2.nested_move :parent => obj_1
    assert_equal [1, 4], [obj_1.left_key, obj_1.right_key]
    obj_3.reload
    obj_4.reload
    obj_3.nested_move :parent => obj_4
    obj_4.nested_move :prev => obj_2
    obj_1.reload
    obj_3.reload
    assert_equal [1, 8], [obj_1.left_key, obj_1.right_key]
    assert_equal [2, 3], [obj_2.left_key, obj_2.right_key]
    assert_equal [4, 7], [obj_4.left_key, obj_4.right_key]
    assert_equal [5, 6], [obj_3.left_key, obj_3.right_key]
    
    # state
    # obj_4        1  8
    #   obj_3        2  7
    #     obj_1        3  6
    #       obj_2        4  5
    obj_4.nested_move
    obj_1.reload
    obj_3.reload
    obj_1.nested_move :parent => obj_3
    obj_4.reload
    obj_2.reload
    assert_equal [1, 8], [obj_4.left_key, obj_4.right_key]
    assert_equal [2, 7], [obj_3.left_key, obj_3.right_key]
    assert_equal [3, 6], [obj_1.left_key, obj_1.right_key]
    assert_equal [4, 5], [obj_2.left_key, obj_2.right_key]
  end

  def test_create_with_key
    obj = NestedWithKey.create :key_value => 1, :value => 1
    assert_equal [1, 2], [obj.left_key, obj.right_key]
    
    obj_1 = NestedWithKey.create :key_value => 2, :value => 1
    assert_equal [1, 2], [obj.left_key, obj.right_key]
    
    obj = NestedWithKey.create :key_value => 1, :value => 2
    assert_equal [3, 4], [obj.left_key, obj.right_key]
  end

  def test_move_with_key
    obj_1_1 = NestedWithKey.create :key_value => 1, :value => 1
    obj_1_2 = NestedWithKey.create :key_value => 1, :value => 2
    
    obj_2_1 = NestedWithKey.create :key_value => 2, :value => 3
    obj_2_2 = NestedWithKey.create :key_value => 2, :value => 4
    assert_equal [3, 4], [obj_2_2.left_key, obj_2_2.right_key]
    
    # Must nothing to do
    obj_2_2.nested_move :parent => obj_1_1
    assert_equal [3, 4, 4], [obj_2_2.left_key, obj_2_2.right_key, obj_2_2.value]
    obj_2_2.nested_move :prev => obj_1_2
    assert_equal [3, 4, 4], [obj_2_2.left_key, obj_2_2.right_key, obj_2_2.value]
    
    obj_1_1.nested_move :parent => obj_1_2
    obj_2_1.nested_move :prev => obj_2_2
    
    assert_equal [1, 4], [obj_1_2.left_key, obj_1_2.right_key]
    assert_equal [2, 3], [obj_1_1.left_key, obj_1_1.right_key]
    
    assert_equal [1, 2], [obj_2_2.left_key, obj_2_2.right_key]
    assert_equal [3, 4], [obj_2_1.left_key, obj_2_1.right_key]
  end
end

class NestedSet < ActiveRecord::Base
  nested_trees
end

class NestedWithKey < ActiveRecord::Base
  nested_trees :with_key => :key_value
end