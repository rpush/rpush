$LOAD_PATH.unshift('bm')
require 'bench'

n = 1_000_000

Rpush.reflect do |on|
  on.error {}
end

Bench.run do |x|
  include Rpush::Reflectable

  x.report(:reflect) do
    n.times do
      reflect(:error, nil)
    end
  end
end
