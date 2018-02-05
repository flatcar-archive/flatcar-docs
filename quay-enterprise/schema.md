Schema for Quay Enterprise

  * AUTHENTICATION_TYPE [string] required<br />
    The authentication engine to use for credential authentication.<br />
    enum: Database, LDAP, JWT, Keystone, OIDC<br />
    Example: `Database`

  * BUILDLOGS_REDIS [object] required<br />
    Connection information for Redis for build logs caching.<br />

        * host [string] required
          The hostname at which Redis is accessible
          Example: `my.redis.cluster`

        * password [string]
            The password to connect to the Redis instance
            Example: `mypassword`

        * port [number]
            The port at which Redis is accessible
            Example: `1234`

  * DB_URI [string] required<br />
    The URI at which to access the database, including any credentials.<br />
    [Reference: https://www.postgresql.org/docs/9.3/static/libpq-connect.html#AEN39495](https://www.postgresql.org/docs/9.3/static/libpq-connect.html#AEN39495)<br />
    Example: `mysql+pymysql://username:password@dns.of.database/quay`

  * DEFAULT_TAG_EXPIRATION [string] required<br />
    The default, configurable tag expiration time for time machine. Defaults to `2w`.<br />
    Pattern: ^[0-9]+(w|m|d|h|s)$

  * DISTRIBUTED_STORAGE_CONFIG [object] required<br />
    Configuration for storage engine(s) to use in Quay. Each key is a unique ID for a storage engine, with the value being a tuple of the type and configuration for that engine.<br />
    Example: `{"local_storage": ["LocalStorage", {"storage_path": "some/path/"}]}`

  * DISTRIBUTED_STORAGE_PREFERENCE [array] required<br />
    The preferred storage engine(s) (by ID in DISTRIBUTED_STORAGE_CONFIG) to use. A preferred engine means it is first checked for pullig and images are pushed to it.<br />
    Min Items: None<br />
    Example: `[u's3_us_east', u's3_us_west']`
     * array item [string]

  * PREFERRED_URL_SCHEME [string] required
    The URL scheme to use when hitting Quay. If Quay is behind SSL *at all*, this *must* be `https`.<br />
    enum: http, https<br />
    Example: `https`

  * SERVER_HOSTNAME [string] required<br />
    The URL at which Quay is accessible, without the scheme.<br />
    Example: `quay.io`

  * TAG_EXPIRATION_OPTIONS [array] required<br />
    The options that users can select for expiration of tags in their namespace(if enabled).<br />
    Min Items: None<br />
        * array item [string]<br />
          Pattern: ^[0-9]+(w|m|d|h|s)$

  * USER_EVENTS_REDIS [object] required<br />
    Connection information for Redis for user event handling.<br />

        * host [string] required
          The hostname at which Redis is accessible
          Example: `my.redis.cluster`

        * password [string]<br />
          The password to connect to the Redis instance.
          Example: `mypassword`

        * port [number]
          The port at which Redis is accessible.
          Example: `1234`

  * ALLOW_PULLS_WITHOUT_STRICT_LOGGING [boolean]<br />
    If true, pulls in which the pull audit log entry cannot be written will still succeed. Useful if the database can fallback into a read-only state and it is desired for pulls to continue during that time. Defaults to False.<br />
    Example: `True`

  * AVATAR_KIND [string]<br />
    The types of avatars to display, either generated inline (local) or Gravatar (gravatar)<br />
    enum: local, gravatar

  * BITTORRENT_ANNOUNCE_URL [string]<br />
    The URL of the announce endpoint on the bittorrent tracker.<br />
    Pattern: ^http(s)?://(.)+$<br />
    Example: `https://localhost:6881/announce`

  * BITTORRENT_PIECE_SIZE [number]<br />
    The bittorent piece size to use. If not specified, defaults to 512 * 1024.<br />
    Example: `524288`

  * CONTACT_INFO [array]<br />
    If specified, contact information to display on the contact page. If only a single piece of contact information is specified, the contact footer will link directly.<br />
    Min Items: 1<br />
    Unique Items: True

        * array item 0 [string]
        Adds a link to send an e-mail
        Pattern: ^mailto:(.)+$
        Example: `mailto:support@quay.io`

        * array item 1 [string]
        Adds a link to visit an IRC chat room
        Pattern: ^irc://(.)+$
        Example: `irc://chat.freenode.net:6665/quay`

        * array item 2 [string]
        Adds a link to call a phone number
        Pattern: ^tel:(.)+$
        Example: `tel:+1-888-930-3475`

        * array item 3 [string]
        Adds a link to a defined URL
        Pattern: ^http(s)?://(.)+$
        Example: `https://twitter.com/quayio`

  * DIRECT_OAUTH_CLIENTID_WHITELIST [array]<br />
    A list of client IDs of *Quay-managed* applications that are allowed to perform direct OAuth approval without user approval.<br />
    Min Items: None<br />
    Unique Items: True<br />
    [Reference: https://coreos.com/quay-enterprise/docs/latest/direct-oauth.html](https://coreos.com/quay-enterprise/docs/latest/direct-oauth.html)
        * array item [string]

  * DISTRIBUTED_STORAGE_DEFAULT_LOCATIONS [array]<br />
    The list of storage engine(s) (by ID in DISTRIBUTED_STORAGE_CONFIG) whose images should be fully replicated, by default, to all other storage engines.<br />
    Min Items: None<br />
    Example: `[u's3_us_east', u's3_us_west']`
        * array item [string]

  * EXTERNAL_TLS_TERMINATION [boolean]<br />
    If TLS is supported, but terminated at a layer before Quay, must be true.<br />
    Example: `True`

  * FEATURE_ACI_CONVERSION [boolean]<br />
    Whether to enable conversion to ACIs. Defaults to False<br />
    Example: `False`

  * FEATURE_ACTION_LOG_ROTATION [boolean]<br />
    Whether or not to rotate old action logs to storage. Defaults to False.<br />
    Example: `False`

  * FEATURE_ADVERTISE_V2 [boolean]<br />
    Whether the v2/ endpoint is visible. Defaults to True.<br />
    Example: `True`

  * FEATURE_ANONYMOUS_ACCESS [boolean]<br />
    Whether to allow anonymous users to browse and pull public repositories.<br /> Defaults to True
    Example: `True`

  * FEATURE_APP_REGISTRY [boolean]<br />
    Whether to enable support for App repositories. Defaults to False.<br />
    Example: `False`

  * FEATURE_BITBUCKET_BUILD [boolean]<br />
    Whether to support Bitbucket build triggers. Defaults to False.<br />
    Example: `False`

  * FEATURE_BITTORRENT [boolean]<br />
    Whether to allow using Bittorrent-based pulls. Defaults to False.<br />
    [Reference: https://coreos.com/quay-enterprise/docs/latest/bittorrent.html](https://coreos.com/quay-enterprise/docs/latest/bittorrent.html)<br />
    Example: `False`

  * FEATURE_BUILD_SUPPORT [boolean]<br />
    Whether to support Dockerfile build. Defaults to True.<br />
    Example: `True`

  * FEATURE_CHANGE_TAG_EXPIRATION [boolean]<br />
    Whether users and organizations are allowed to change the tag expiration for tags in their namespace. Defaults to True.<br />
    Example: `False`

  * FEATURE_DIRECT_LOGIN [boolean]<br />
    Whether users can directly login to the UI. Defaults to True.<br />
    Example: `True`

  * FEATURE_GITHUB_BUILD [boolean]<br />
    Whether to support GitHub build triggers. Defaults to False.<br />
    Example: `False`

  * FEATURE_GITHUB_LOGIN [boolean]<br />
    Whether GitHub login is supported. Defaults to False.<br />
    Example: `False`

  * FEATURE_GITLAB_BUILD [boolean]<br />
    Whether to support GitLab build triggers. Defaults to False.<br />
    Example: `False`

  * FEATURE_GOOGLE_LOGIN [boolean]<br />
    Whether Google login is supported. Defaults to False.<br />
    Example: `False`

  * FEATURE_INVITE_ONLY_USER_CREATION [boolean]<br />
    Whether users being created must be invited by another user. Defaults to False.<br />
    Example: `False`

  * FEATURE_LIBRARY_SUPPORT [boolean]<br />
    Whether to allow for "namespace-less" repositories when pulling and pushing from Docker. Defaults to True.<br />
    Example: `True`

  * FEATURE_MAILING [boolean]<br />
    Whether emails are enabled. Defaults to True.<br />
    Example: `True`

  * FEATURE_PARTIAL_USER_AUTOCOMPLETE [boolean]<br />
    If set to true, autocompletion will apply to partial usernames. Defaults to True.<br />
    Example: `True`

  * FEATURE_PERMANENT_SESSIONS [boolean]<br />
    Whether sessions are permanent. Defaults to True.<br />
    Example: `True`

  * FEATURE_PROXY_STORAGE [boolean]<br />
    Whether to proxy all direct download URLs in storage via the registry nginx. Defaults to False.<br />
    Example: `False`

  * FEATURE_PUBLIC_CATALOG [boolean]<br />
    If set to true, the _catalog endpoint returns public repositories. Otherwise, only private repositories can be returned. Defaults to False.<br />
    Example: `False`

  * FEATURE_READER_BUILD_LOGS [boolean]<br />
    If set to true, build logs may be read by those with read access to the repo, rather than only write access or admin access. Defaults to False.<br />
    Example: `False`

  * FEATURE_REQUIRE_ENCRYPTED_BASIC_AUTH [boolean]<br />
    Whether non-encrypted passwords (as opposed to encrypted tokens) can be used for basic auth. Defaults to False.<br />
    Example: `False`

  * FEATURE_REQUIRE_TEAM_INVITE [boolean]<br />
    Whether to require invitations when adding a user to a team. Defaults to True.<br />
    Example: `True`

  * FEATURE_SECURITY_NOTIFICATIONS [boolean]<br />
    If the security scanner is enabled, whether to turn of/off security notificaitons. Defaults to False.<br />
    Example: `False`

  * FEATURE_SECURITY_SCANNER [boolean]<br />
    Whether to turn of/off the security scanner. Defaults to False<br />
    [Reference: https://coreos.com/quay-enterprise/docs/latest/security-scanning.html](https://coreos.com/quay-enterprise/docs/latest/security-scanning.html)<br />
    Example: `False`

  * FEATURE_STORAGE_REPLICATION [boolean]<br />
    Whether to automatically replicate between storage engines. Defaults to False.<br />
    Example: `False`

  * FEATURE_SUPER_USERS [boolean]<br />
    Whether super users are supported. Defaults to True.
    Example: `True`

  * FEATURE_TEAM_SYNCING [boolean]<br />
    Whether to allow for team membership to be synced from a backing group in the authentication engine (LDAP or Keystone).<br />
    Example: `True`

  * FEATURE_USER_CREATION [boolean]<br />
    Whether users can be created (by non-super users). Defaults to True.
    Example: `True`

  * FEATURE_USER_METADATA [boolean]<br />
    Whether to collect and support user metadata. Defaults to False.<br />
    Example: `False`

  * GITHUB_LOGIN_CONFIG [object]<br />
    Configuration for using GitHub (Enterprise) as an external login provider.<br />
    [Reference: https://coreos.com/quay-enterprise/docs/latest/github-auth.html](https://coreos.com/quay-enterprise/docs/latest/github-auth.html)

        * ALLOWED_ORGANIZATIONS [array]
        The names of the GitHub (Enterprise) organizations whitelisted to work with the ORG_RESTRICT option.
        Min Items: None
        Unique Items: True
              * array item [string]

        * API_ENDPOINT [string]
        The endpoint of the GitHub (Enterprise) API to use. Must be overridden for github.com.
        Example: `https://api.github.com/`

        * CLIENT_ID [string] required
        The registered client ID for this Quay instance; cannot be shared with GITHUB_TRIGGER_CONFIG.
        [Reference: https://coreos.com/quay-enterprise/docs/latest/github-app.html](https://coreos.com/quay-enterprise/docs/latest/github-app.html)
        Example: `0e8dbe15c4c7630b6780`

        * CLIENT_SECRET [string] required
        The registered client secret for this Quay instance.
        [Reference: https://coreos.com/quay-enterprise/docs/latest/github-app.html](https://coreos.com/quay-enterprise/docs/latest/github-app.html)
        Example: `e4a58ddd3d7408b7aec109e85564a0d153d3e846`

        * GITHUB_ENDPOINT [string required
        The endpoint of the GitHub (Enterprise) being hit.
        Example: `https://github.com/`

        * ORG_RESTRICT [boolean]
        If true, only users within the organization whitelist can login using this provider.
        Example: `True`

  * GITHUB_TRIGGER_CONFIG [object]<br />
    Configuration for using GitHub (Enterprise) for build triggers.<br />
    [Reference: https://coreos.com/quay-enterprise/docs/latest/github-build.html](https://coreos.com/quay-enterprise/docs/latest/github-build.html)

        * API_ENDPOINT [string]
        The endpoint of the GitHub (Enterprise) API to use. Must be overridden for github.com.
        Example: `https://api.github.com/`

        * CLIENT_ID [string] required
        The registered client ID for this Quay instance; cannot be shared with GITHUB_LOGIN_CONFIG.
        [Reference: https://coreos.com/quay-enterprise/docs/latest/github-app.html](https://coreos.com/quay-enterprise/docs/latest/github-app.html)
        Example: `0e8dbe15c4c7630b6780`

        * CLIENT_SECRET [string] required
        The registered client secret for this Quay instance.
        [Reference: https://coreos.com/quay-enterprise/docs/latest/github-app.html](https://coreos.com/quay-enterprise/docs/latest/github-app.html)
        Example: `e4a58ddd3d7408b7aec109e85564a0d153d3e846`

        * GITHUB_ENDPOINT [string] required
          The endpoint of the GitHub (Enterprise) being hit.
          Example: `https://github.com/`

  * GITLAB_TRIGGER_CONFIG [object]<br />
    Configuration for using Gitlab (Enterprise) for external authentication.

        * CLIENT_ID [string] required
          The registered client ID for this Quay instance.
          Example: `0e8dbe15c4c7630b6780`

        * CLIENT_SECRET [string] required
        The registered client secret for this Quay instance.
        Example: `e4a58ddd3d7408b7aec109e85564a0d153d3e846`

        * GITLAB_ENDPOINT [string] required
        The endpoint at which Gitlab(Enterprise) is running.
        Example: `https://gitlab.com`

  * GOOGLE_LOGIN_CONFIG [object]<br />
  Configuration for using Google for external authentication<br />

        * CLIENT_ID [string] required
        The registered client ID for this Quay instance.
        Example: `0e8dbe15c4c7630b6780`

        * CLIENT_SECRET [string] required
        The registered client secret for this Quay instance.
        Example: `e4a58ddd3d7408b7aec109e85564a0d153d3e846`

  * MAIL_DEFAULT_SENDER [string]<br />
    If specified, the e-mail address used as the `from` when Quay sends e-mails. If none, defaults to `support@quay.io`.<br />
    Example: `support@myco.com`

  * MAIL_PASSWORD [string]<br />
    The SMTP password to use when sending e-mails.<br />
    Example: `mypassword`

  * MAIL_PORT [number]<br />
    The SMTP port to use. If not specified, defaults to 587.<br />
    Example: `588`

  * MAIL_SERVER [string]<br />
    The SMTP server to use for sending e-mails. Only required if FEATURE_MAILING is set to true.<br />
    Example: `smtp.somedomain.com`

  * MAIL_USERNAME [string]<br />
    The SMTP username to use when sending e-mails.<br />
    Example: `myuser`

  * MAIL_USE_TLS [boolean]<br />
    If specified, whether to use TLS for sending e-mails.<br />
    Example: `True`

  * MAXIMUM_LAYER_SIZE [string]<br />
    Maximum allowed size of an image layer. Defaults to 20G.<br />
    Pattern: ^[0-9]+(G|M)$
    Example: `100G`

  * PUBLIC_NAMESPACES [array]<br />
    If a namespace is defined in the public namespace list, then it will appear on *all* user's repository list pages, regardless of whether that user is a member of the namespace. Typically, this is used by an enterprise customer in configuring a set of "well-known" namespaces.<br />
    Min Items: None
    Unique Items: True
        * array item [string]

  * REGISTRY_TITLE [string]<br />
    If specified, the long-form title for the registry. Defaults to `Quay Enterprise`.<br />
    Example: `Corp Container Service`

  * REGISTRY_TITLE_SHORT [string]<br />
    If specified, the short-form title for the registry. Defaults to `Quay Enterprise`.<br />
    Example: `CCS`

  * SECURITY_SCANNER_ENDPOINT [string]<br />
    The endpoint for the security scanner.<br />
    Pattern: ^http(s)?://(.)+$
    Example: `http://192.168.99.101:6060`

  * SECURITY_SCANNER_INDEXING_INTERVAL [number]<br />
    The number of seconds between indexing intervals in the security scanner. Defaults to 30.<br />
    Example: `30`

  * SUPER_USERS [array]<br />
    Quay usernames of those users to be granted superuser privileges.<br />
    Min Items: None
    Unique Items: True
        * array item [string]

  * TEAM_RESYNC_STALE_TIME [string]<br />
    If team syncing is enabled for a team, how often to check its membership and resync if necessary(Default: 30m).<br />
    Pattern: ^[0-9]+(w|m|d|h|s)$<br />
    Example: `2h`