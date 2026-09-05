# Production database upgrade repair

User authorizes fixing statistics and auditing related features. Runtime: formal Application Support database is schema 5; reading/timing/history tables absent; library and statistics fail. Old production-path migration guards prevent versions 6–8.

Requirements: preserve all existing user rows; make a consistent SQLite backup before each required upgrade; migrate real and copied existing databases through the same path; abort on backup/migration error; preserve future-version rejection; verify idempotence. Do not synthesize historical playback that was never saved.

Sequence: reproduce schema-5 default-path failure under an isolated CFFIXED_USER_HOME; fix migration guards and snapshot backup; verify schema 3–8, legacy data preservation, backup integrity and failed-upgrade retry; test a SQLite backup of the user's DB; build Debug/Release; open new Release only after copy verification; verify actual library/history/statistics and new session persistence; restart and recheck. Inspect nearby refresh/write behavior and report evidence/limits. Request independent review before delivery.

Formal project remains untouched. Work branch codex/experience-restoration, base f0ffcb19463435f8f8e952f138bd28863883f30a. No main merge or release tag.
