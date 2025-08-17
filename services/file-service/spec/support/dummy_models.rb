# 테스트용 더미 모델들
class Task
  def self.find(id)
    new(id: id)
  end

  def initialize(attributes = {})
    @id = attributes[:id]
  end

  attr_reader :id
end

class User
  def self.find(id)
    new(id: id)
  end

  def initialize(attributes = {})
    @id = attributes[:id]
  end

  attr_reader :id
end