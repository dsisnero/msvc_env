module WithEnv
  UNDEF = "____@@@@@@UNDEF****211_____"

  def with_env(env : Hash(String, String), &)
    current_values = env.each_with_object(Hash(String, String).new) do |(k, v), obj|
      obj[k] = ENV.fetch(k, UNDEF)
    end
    env.each_key { |key| ENV[key] = env[key] }
    yield
  ensure
    current_values.not_nil!.each do |k, v|
      if v == UNDEF
        ENV.delete(k)
      else
        ENV[k] = v
      end
    end
  end
end
