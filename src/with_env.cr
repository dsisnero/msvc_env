module WithEnv

  class Undef
  end
  
  UNDEF = "____@@@@@@UNDEF****211_____"

  def with_env(env : Hash(String, String), &)
    old_env = nil
    begin
      old_env = env.each_with_object(Hash(String, String).new) do |(k, v), obj|
        obj[k] = ENV.fetch(k, UNDEF)
        ENV[k] = v
      end
      yield
    ensure
      old_env.not_nil!.each do |k, v|
        if v == UNDEF
          ENV.delete(k)
        else
          ENV[k] = v
        end
      end
    end
  end
end
