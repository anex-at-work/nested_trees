# nested_trees

NestedTrees allows you use [nested set model](http://en.wikipedia.org/wiki/Nested_set_model) simple and easy.

## Installation

In your Gemfile:

```ruby
gem 'nested_sets', :git => 'git://github.com/anex-at-work/nested_trees.git'
```

## Usage

### Basic setup

Model must have additional two fields, knowns as `left key` and `right key`. 

In your model (showing default values):
```ruby
nested_trees :left_key => 'left_key',
             :right_key => 'right_key',
             :with_key => nil
```

With non-nil options `with_key` tree can have nested trees, i.e.:
without additional key:
```
lk    rk
1     4
  2   3
5     6
```

with additional key:
```
lk    rk   wk
1     4    1
  2   3    1
1     2    2
```

### Create

Just create new object in your model:
```ruby
NestedSet.create :value => 1
```

After creatting, new node will be placed as last position of tree.

### Move

For moving, use `nested_move` method.
Options:
**parent** - parent node or nil
**prev** - previous node or nil

Ex. (from tests):

move obj_1 to _right_ of obj_2
```ruby
obj_1.nested_move :prev => obj_2
```

move obj_1 to _first position_
```ruby
obj_1.nested_move
```

move obj_1 to the last child of parent obj_2
```ruby
obj_1.nested_move :parent => obj_2
``` 

## Not implemented yet:

### Removing

### Levels

Please, use views [with subqueries](http://en.wikipedia.org/wiki/Nested_set_model#Variations) 