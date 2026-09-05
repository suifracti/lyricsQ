"""Disposable default-home upgrade matrix. Never accepts a live user database."""
import os
import pathlib
import shutil
import sqlite3
import subprocess
import sys

binary, fixture, root = map(pathlib.Path, sys.argv[1:])
assert str(root.resolve()).startswith('/private/tmp/') or str(root.resolve()).startswith('/tmp/')

def create(name, source=fixture):
    home = root / name
    db = home / 'Library/Application Support/SpotifyLyrics/SpotifyLyrics.sqlite3'
    db.parent.mkdir(parents=True)
    shutil.copyfile(source, db)
    return home, db

def execute(db, sql):
    with sqlite3.connect(db) as c:
        c.executescript(sql)

def snapshot(db):
    with sqlite3.connect(db) as c:
        tables = [r[0] for r in c.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'schema_migrations'")]
        return {t: ([r[1] for r in c.execute(f'PRAGMA table_info("{t}")')], sorted(c.execute(f'SELECT * FROM "{t}"').fetchall(), key=repr)) for t in tables}

def preserved(db, before):
    with sqlite3.connect(db) as c:
        assert c.execute('PRAGMA integrity_check').fetchone()[0] == 'ok'
        assert not c.execute('PRAGMA foreign_key_check').fetchall()
        for t, (columns, rows) in before.items():
            names = ','.join('"'+n+'"' for n in columns)
            assert sorted(c.execute(f'SELECT {names} FROM "{t}"').fetchall(), key=repr) == rows, t

def run(home, failure=False):
    env = dict(os.environ, CFFIXED_USER_HOME=str(home))
    env.pop('UPGRADE_FIXTURE_EXPORT', None)
    env.pop('SPOTIFYLYRICS_DATABASE_PATH', None)
    subprocess.run([str(binary), '--existing'] + (['--expect-failure'] if failure else []), env=env, check=True)

# Actual v5 path, then derive additive v6/v7 schemas from the upgraded copy.
home5, db5 = create('v5')
before = snapshot(db5)
run(home5)
preserved(db5, before)
for version in (6, 7, 8, 9):
    home, db = create(f'v{version}', db5)
    drops = 'DROP INDEX lyrics_versions_one_preferred; ALTER TABLE lyrics_versions DROP COLUMN is_preferred;' if version < 9 else ''
    if version < 8: drops += 'DROP TABLE listening_history_sessions;'
    if version < 7: drops += 'DROP TABLE lyrics_timing_versions;'
    execute(db, drops + f'DELETE FROM schema_migrations WHERE version>{version}; PRAGMA user_version={version};')
    before = snapshot(db)
    run(home)
    preserved(db, before)

# Restore the pre-v5 translation shape and pre-v4 redirect shape in fixtures.
for version in (3, 4):
    home, db = create(f'v{version}')
    execute(db, 'DROP INDEX translation_versions_engine_lookup;' + ''.join(f'ALTER TABLE translation_versions DROP COLUMN {column};' for column in ['engine_id', 'prompt_preset_id', 'profile_id', 'profile_snapshot', 'temperature', 'workflow_id', 'fallback_strategy', 'is_draft', 'is_archived']))
    if version == 3:
        execute(db, 'DROP TABLE track_identity_redirects; DROP TABLE track_identity_merge_audit; DROP INDEX schema_migrations_migration_id; ALTER TABLE schema_migrations DROP COLUMN migration_id;')
    execute(db, f'DELETE FROM schema_migrations WHERE version>{version}; PRAGMA user_version={version};')
    before = snapshot(db)
    run(home)
    preserved(db, before)

# A schema conflict must roll back that version, preserve rows, and allow retry.
home, db = create('failed-migration')
execute(db, 'CREATE TABLE reading_versions(broken TEXT);')
before = snapshot(db)
run(home, failure=True)
preserved(db, before)
with sqlite3.connect(db) as c: assert c.execute('PRAGMA user_version').fetchone()[0] == 5
execute(db, 'DROP TABLE reading_versions;')
for p in db.parent.glob('*.pre-v*.sqlite3'): p.unlink()
run(home)

# A failed backup must not upgrade the source or leave a false recovery file.
home, db = create('failed-backup')
before = snapshot(db)
db.parent.chmod(0o500)
try: run(home, failure=True)
finally: db.parent.chmod(0o700)
preserved(db, before)
with sqlite3.connect(db) as c: assert c.execute('PRAGMA user_version').fetchone()[0] == 5
assert not list(db.parent.glob('*.pre-v*'))
run(home)

home, db = create('future')
execute(db, 'PRAGMA user_version=999;')
before = snapshot(db)
run(home, failure=True)
preserved(db, before)
with sqlite3.connect(db) as c: assert c.execute('PRAGMA user_version').fetchone()[0] == 999
assert not list(db.parent.glob('*.pre-v*'))
print('Upgrade matrix PASS: versions 3–9; row preservation; rollback/retry; backup failure/retry; future rejection')
