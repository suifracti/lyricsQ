# Title-only lyric recovery repair

User asked to continue after the current song displayed no lyrics. Read-only LRCLIB requests reproduce: Marigold + 愛繆 returns no records; title-only returns Aimyon records including a synchronized 307-second entry. No artist alias is automatically assumed or hardcoded.

Root causes to test: manager restores the artist removed by query planning; LRCLIB always applies artist/track filters and exact-get; manual exact-title evidence cannot reach the existing candidate-only exception when artist metadata differs.

- [ ] Add isolated behavioral tests for planned artist omission, HTTP query shape, candidate-only manual recovery, identity/conflict guards and end-to-end fake provider. Confirm failures before source changes.
- [ ] Preserve missing query artist, use LRCLIB free-text search for such probes, and consistently retain title-matching manual candidates without promoting automatic adoption.
- [ ] Run focused and existing retrieval/query/provider tests, read-only live provider probe, independent review, Debug/Release.
- [ ] Deliver distinct preview and expose manual candidates for the current song; do not automatically adopt an unverified artist alias.

All tests use generated lyrics and no user DB. Continue the existing feature branch from 63bdc46 so the stage correction remains present.
