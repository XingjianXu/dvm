require 'dvm/action'

module Dvm
  class Dsl

    def initialize
      @actions = {}
    end


    def add_dvm(dvm_file)
      contents ||= File.read(dvm_file)
      instance_eval(contents, dvm_file.to_s, 1)
    end


    def action(name, title, &block)
      action = Action.new name, title, block
      @actions[name] = action
    end


    def run_action(name)
      @actions[name].run
    end


  end
end
