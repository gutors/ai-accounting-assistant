module GoogleOauth
  def self.scopes
    %w[openid email]
  end

  def self.scope_string
    scopes.join(",")
  end
end
