module Erbee
  class CLI
    def self.start(args)
      model_name = args[0] || raise("Please specify a model name")
      explorer = AssociationExplorer.new(model_name)
      model_infos = explorer.explore

      renderer = DiagramRenderer.new(model_infos)
      renderer.render
    end
  end
end

