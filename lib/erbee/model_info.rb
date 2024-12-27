module Erbee
  ModelInfo = Struct.new(
    :model_class,
    :associations,
    :columns,
    keyword_init: true
  )
end

