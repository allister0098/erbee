# spec/erbee/diagram_renderer_spec.rb

require "spec_helper"
require "tempfile"
require_relative "../erbee/support/random_model_info_helper"

RSpec.describe Erbee::DiagramRenderer do
  include RandomModelInfoHelper

  it "generates a Mermaid erDiagram for 50 random tables using Tempfile and deletes it after" do
    # 1. Generate random ModelInfo array with fixed seed
    model_infos = create_random_model_infos(50, seed = 12345)

    # 2. Create a Tempfile for output
    tmpfile = Tempfile.new(["random_erdiagram", ".md"])

    # 3. Configure Erbee to output to the Tempfile
    Erbee.configure do |config|
      config.output_path = tmpfile.path
    end

    # 4. Render the diagram
    renderer = Erbee::DiagramRenderer.new(model_infos)
    renderer.render

    # 5. Assertions
    expect(File).to exist(tmpfile.path)
    content = File.read(tmpfile.path)

    # Check that the content includes the Mermaid code block and 'erDiagram'
    expect(content).to include("```mermaid")
    expect(content).to include("erDiagram")

    # Check that some table definitions are present
    expect(content).to include("table01 {")
    expect(content).to include("table50 {")

    # Check that relationships are defined
    # Example: "table01 ||--|{ table02 : "1:N""
    expect(content).to match(/table\d{2}\s+\|\|--\|\{\s+table\d{2}/)

    # Output the path for debugging (file will be deleted)
    puts "Generated ER diagram saved at: #{tmpfile.path}"

    # 6. Cleanup: close and delete the Tempfile
    tmpfile.close
    tmpfile.unlink  # This deletes the file
  end
end