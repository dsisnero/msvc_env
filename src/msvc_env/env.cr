require "./controller"

module MsvcEnv
  def self.with_env(&)
    controller = MsvcEnv::Controller.new
    controller.msvc_env do
      yield
    end
  end
end
