# In this file, we load production configuration and secrets
# from environment variables at runtime
import Config

get_env_as_boolean = fn key, default ->
  System.get_env(key, default)
  |> String.downcase()
  |> String.trim()
  |> case do
    "true" -> true
    _ -> false
  end
end

# Appsignal client key is required for appsignal integration
config :appsignal, :client_key, System.get_env("APPSIGNAL_PUSH_API_KEY", nil)

# Configure runtime log level if LOG_LEVEL is set
case System.get_env("LOG_LEVEL", nil) do
  nil ->
    nil

  log_level ->
    config :logger, level: String.to_existing_atom(log_level)
end

if get_env_as_boolean.("APPSIGNAL_ENABLE_LOGGING", "false") do
  config :logger, backends: [:console, {Appsignal.Logger.Backend, [group: "phoenix"]}]
end

# Production-only configurations
if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :oli, Oli.Repo,
    url: database_url,
    database: System.get_env("DB_NAME", "oli"),
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    timeout: 600_000,
    ownership_timeout: 600_000,
    socket_options: maybe_ipv6

  config :ex_aws, :s3,
    region: System.get_env("AWS_REGION", "us-east-1"),
    scheme: System.get_env("AWS_S3_SCHEME", "https") <> "://",
    port: System.get_env("AWS_S3_PORT", "443") |> String.to_integer(),
    host: System.get_env("AWS_S3_HOST", "s3.amazonaws.com")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  live_view_salt =
    System.get_env("LIVE_VIEW_SALT") ||
      raise """
      environment variable LIVE_VIEW_SALT is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host =
    System.get_env("HOST") ||
      raise """
      environment variable HOST is missing.
      For example: host.example.com
      """

  s3_media_bucket_name =
    System.get_env("S3_MEDIA_BUCKET_NAME") ||
      raise """
      environment variable S3_MEDIA_BUCKET_NAME is missing.
      For example: torus-media
      """

  s3_xapi_bucket_name =
    System.get_env("S3_XAPI_BUCKET_NAME") ||
      raise """
      environment variable S3_XAPI_BUCKET_NAME is missing.
      For example: torus-xapi
      """

  if System.get_env("PAYMENT_PROVIDER") == "stripe" &&
       (!System.get_env("STRIPE_PUBLIC_SECRET") || !System.get_env("STRIPE_PRIVATE_SECRET")) do
    raise """
    Stripe payment provider not configured correctly. Both STRIPE_PUBLIC_SECRET
    and STRIPE_PRIVATE_SECRET values must be set.
    """
  end

  if System.get_env("PAYMENT_PROVIDER") == "cashnet" &&
       (!System.get_env("CASHNET_STORE") || !System.get_env("CASHNET_CHECKOUT_URL") ||
          !System.get_env("CASHNET_CLIENT") || !System.get_env("CASHNET_GL_NUMBER")) do
    raise """
    Cashnet payment provider not configured correctly. CASHNET_STORE, CASHNET_CHECKOUT_URL,
    CASHNET_CLIENT and CASHNET_GL_NUMBER values must be set.
    """
  end

  media_url =
    System.get_env("MEDIA_URL") ||
      raise """
      environment variable MEDIA_URL is missing.
      For example: your_s3_media_bucket_url.s3.amazonaws.com
      """

  # General OLI app config
  config :oli,
    s3_media_bucket_name: s3_media_bucket_name,
    s3_xapi_bucket_name: s3_xapi_bucket_name,
    media_url: media_url,
    email_from_name: System.get_env("EMAIL_FROM_NAME", "OLI Torus"),
    email_from_address: System.get_env("EMAIL_FROM_ADDRESS", "admin@example.edu"),
    email_reply_to: System.get_env("EMAIL_REPLY_TO", "admin@example.edu"),
    slack_webhook_url: System.get_env("SLACK_WEBHOOK_URL"),
    load_testing_mode: get_env_as_boolean.("LOAD_TESTING_MODE", "false"),
    payment_provider: System.get_env("PAYMENT_PROVIDER", "none"),
    blackboard_application_client_id: System.get_env("BLACKBOARD_APPLICATION_CLIENT_ID"),
    branding: [
      name: System.get_env("BRANDING_NAME", "OLI Torus"),
      logo: System.get_env("BRANDING_LOGO", "/images/oli_torus_logo.png"),
      logo_dark:
        System.get_env(
          "BRANDING_LOGO_DARK",
          System.get_env("BRANDING_LOGO", "/images/oli_torus_logo_dark.png")
        ),
      favicons: System.get_env("BRANDING_FAVICONS_DIR", "/favicons")
    ],
    node_js_pool_size: String.to_integer(System.get_env("NODE_JS_POOL_SIZE", "2")),
    screen_idle_timeout_in_seconds:
      String.to_integer(System.get_env("SCREEN_IDLE_TIMEOUT_IN_SECONDS", "1800")),
    always_use_persistent_login_sessions:
      get_env_as_boolean.("ALWAYS_USE_PERSISTENT_LOGIN_SESSIONS", "false"),
    log_incomplete_requests: get_env_as_boolean.("LOG_INCOMPLETE_REQUESTS", "true")

  default_description = """
  The Open Learning Initiative enables research and experimentation with all aspects of the learning experience.
  As a leader in higher education's innovation of online learning, we're a growing research and production project exploring effective approaches since the early 2000s.
  """

  config :oli, :vendor_property,
    workspace_logo:
      System.get_env("VENDOR_PROPERTY_WORKSPACE_LOGO", "/branding/prod/oli_torus_icon.png"),
    product_full_name:
      System.get_env("VENDOR_PROPERTY_PRODUCT_FULL_NAME", "Open Learning Initiative"),
    product_short_name: System.get_env("VENDOR_PROPERTY_PRODUCT_SHORT_NAME", "OLI Torus"),
    product_description:
      System.get_env(
        "VENDOR_PROPERTY_PRODUCT_DESCRIPTION",
        default_description
      ),
    product_learn_more_link:
      System.get_env("VENDOR_PROPERTY_PRODUCT_LEARN_MORE_LINK", "https://oli.cmu.edu"),
    company_name: System.get_env("VENDOR_PROPERTY_COMPANY_NAME", "Carnegie Mellon University"),
    company_address:
      System.get_env(
        "VENDOR_PROPERTY_COMPANY_ADDRESS",
        "5000 Forbes Ave, Pittsburgh, PA 15213 US"
      ),
    support_email: System.get_env("VENDOR_PROPERTY_SUPPORT_EMAIL")

  # optional emerald cloudlab configuration
  config :oli,
    ecl_username: System.get_env("ECL_USERNAME", ""),
    ecl_password: System.get_env("ECL_PASSWORD", "")

  config :oli, :stripe_provider,
    public_secret: System.get_env("STRIPE_PUBLIC_SECRET"),
    private_secret: System.get_env("STRIPE_PRIVATE_SECRET")

  config :oli, :cashnet_provider,
    cashnet_store: System.get_env("CASHNET_STORE"),
    cashnet_checkout_url: System.get_env("CASHNET_CHECKOUT_URL"),
    cashnet_client: System.get_env("CASHNET_CLIENT"),
    cashnet_gl_number: System.get_env("CASHNET_GL_NUMBER")

  config :oli, :upgrade_experiment_provider,
    url: System.get_env("UPGRADE_EXPERIMENT_PROVIDER_URL"),
    user_url: System.get_env("UPGRADE_EXPERIMENT_USER_URL"),
    api_token: System.get_env("UPGRADE_EXPERIMENT_PROVIDER_API_TOKEN")

  # Configure reCAPTCHA
  config :oli, :recaptcha,
    verify_url: "https://www.google.com/recaptcha/api/siteverify",
    timeout: 5000,
    site_key: System.get_env("RECAPTCHA_SITE_KEY"),
    secret: System.get_env("RECAPTCHA_PRIVATE_KEY")

  rule_evaluator_provider =
    case System.get_env("RULE_EVALUATOR_PROVIDER") do
      nil -> Oli.Delivery.Attempts.ActivityLifecycle.NodeEvaluator
      provider -> Module.concat([Oli, Delivery, Attempts, ActivityLifecycle, provider])
    end

  config :oli, :rule_evaluator,
    dispatcher: rule_evaluator_provider,
    aws_fn_name: System.get_env("EVAL_LAMBDA_FN_NAME", "rules"),
    aws_region: System.get_env("EVAL_LAMBDA_REGION", "us-east-1")

  variable_substitution_provider =
    case System.get_env("VARIABLE_SUBSTITUTION_PROVIDER") do
      nil -> Oli.Activities.Transformers.VariableSubstitution.NoOpImpl
      provider -> Module.concat([Oli, Activities, Transformers, VariableSubstitution, provider])
    end

  config :oli, :variable_substitution,
    dispatcher: variable_substitution_provider,
    aws_fn_name: System.get_env("VARIABLE_SUBSTITUTION_LAMBDA_FN_NAME", "eval"),
    aws_region: System.get_env("VARIABLE_SUBSTITUTION_LAMBDA_REGION", "us-east-1"),
    rest_endpoint_url: System.get_env("VARIABLE_SUBSTITUTION_REST_ENDPOINT_URL", "us-east-1")

  # Configure help
  # HELP_PROVIDER env var must be a string representing an existing provider module, such as "FreshdeskHelp"
  help_provider =
    case System.get_env("HELP_PROVIDER") do
      nil -> Oli.Help.Providers.FreshdeskHelp
      provider -> Module.concat([Oli, Help, Providers, provider])
    end

  config :oli, :help, dispatcher: help_provider

  # Configurable http/https protocol options for cowboy
  # https://ninenines.eu/docs/en/cowboy/2.5/manual/cowboy_http/
  http_max_header_name_length =
    System.get_env("HTTP_MAX_HEADER_NAME_LENGTH", "64") |> String.to_integer()

  http_max_header_value_length =
    System.get_env("HTTP_MAX_HEADER_VALUE_LENGTH", "4096") |> String.to_integer()

  http_max_headers = System.get_env("HTTP_MAX_HEADERS", "100") |> String.to_integer()

  if System.get_env("PHX_SERVER") do
    config :oli, OliWeb.Endpoint, server: true
  end

  config :oli, OliWeb.Endpoint,
    http: [
      :inet6,
      port: String.to_integer(System.get_env("HTTP_PORT", "80")),
      protocol_options: [
        max_header_name_length: http_max_header_name_length,
        max_header_value_length: http_max_header_value_length,
        max_headers: http_max_headers
      ]
    ],
    url: [
      scheme: System.get_env("SCHEME", "https"),
      host: host,
      port: String.to_integer(System.get_env("PORT", "443"))
    ],
    secret_key_base: secret_key_base,
    live_view: [signing_salt: live_view_salt]

  if System.get_env("SSL_CERT_PATH") && System.get_env("SSL_KEY_PATH") do
    config :oli, OliWeb.Endpoint,
      https: [
        port: 443,
        otp_app: :oli,
        keyfile: System.get_env("SSL_CERT_PATH", "priv/ssl/localhost.key"),
        certfile: System.get_env("SSL_KEY_PATH", "priv/ssl/localhost.crt"),
        protocol_options: [
          max_header_name_length: http_max_header_name_length,
          max_header_value_length: http_max_header_value_length,
          max_headers: http_max_headers
        ]
      ]
  end

  # Configure Mnesia directory (used by pow persistent sessions)
  config :mnesia, :dir, to_charlist(System.get_env("MNESIA_DIR", ".mnesia"))

  truncate =
    System.get_env("LOGGER_TRUNCATE", "8192")
    |> String.downcase()
    |> case do
      "infinity" ->
        :infinity

      val ->
        String.to_integer(val)
    end

  config :logger, truncate: truncate

  # Configure Privacy Policies link
  config :oli, :privacy_policies,
    url: System.get_env("PRIVACY_POLICIES_URL", "https://www.cmu.edu/legal/privacy-notice.html")

  # Configure footer text and links
  config :oli, :footer,
    text: System.get_env("FOOTER_TEXT", ""),
    link_1_location: System.get_env("FOOTER_LINK_1_LOCATION", ""),
    link_1_text: System.get_env("FOOTER_LINK_1_TEXT", ""),
    link_2_location: System.get_env("FOOTER_LINK_2_LOCATION", ""),
    link_2_text: System.get_env("FOOTER_LINK_2_TEXT", "")

  # Configure if age verification checkbox appears on learner account creation
  config :oli, :age_verification, is_enabled: System.get_env("IS_AGE_VERIFICATION_ENABLED", "")

  config :oli, :auth_providers,
    google_client_id: System.get_env("GOOGLE_CLIENT_ID", ""),
    google_client_secret: System.get_env("GOOGLE_CLIENT_SECRET", ""),
    author_github_client_id: System.get_env("AUTHOR_GITHUB_CLIENT_ID", ""),
    author_github_client_secret: System.get_env("AUTHOR_GITHUB_CLIENT_SECRET", ""),
    user_github_client_id: System.get_env("USER_GITHUB_CLIENT_ID", ""),
    user_github_client_secret: System.get_env("USER_GITHUB_CLIENT_SECRET", "")

  # Configure libcluster for horizontal scaling
  # Take into account that different strategies could use different config options
  config :libcluster,
    topologies: [
      oli:
        case System.get_env("LIBCLUSTER_STRATEGY", "Cluster.Strategy.Gossip") do
          "ClusterEC2.Strategy.Tags" = ec2_strategy ->
            [
              strategy: Module.concat([ec2_strategy]),
              config: [
                ec2_tagname: System.get_env("LIBCLUSTER_EC2_STRATEGY_TAG_NAME", ""),
                ec2_tagvalue: System.get_env("LIBCLUSTER_EC2_STRATEGY_TAG_VALUE", ""),
                app_prefix: System.get_env("LIBCLUSTER_EC2_STRATEGY_APP_PREFIX", "oli")
              ]
            ]

          strategy ->
            [
              strategy: Module.concat([strategy])
            ]
        end
    ]

  config :oli, :datashop,
    cache_limit: String.to_integer(System.get_env("DATASHOP_CACHE_LIMIT", "200"))
end
