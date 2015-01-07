module Dvm::Action



  class Action

    attr_accessor :name, :title, :desc

    def initialize(name, title, block)
      @name = name
      @title = title
      @block = block
    end


    def run
      block.call
    end

  end

end
