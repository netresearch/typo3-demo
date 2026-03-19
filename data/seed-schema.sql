-- Extension DB schema that TCA auto-schema cannot derive.
-- These columns/tables use varbinary, blob, char, or custom indexes
-- not expressible via TCA column definitions.

-- nr_passkeys_fe: fe_users columns (TCA defines them as passthrough/number
-- but extension:setup may not create them on first boot with existing DB)
ALTER TABLE fe_users ADD COLUMN IF NOT EXISTS passkey_grace_period_start int(11) unsigned NOT NULL DEFAULT 0;
ALTER TABLE fe_users ADD COLUMN IF NOT EXISTS passkey_nudge_until int(11) unsigned NOT NULL DEFAULT 0;
ALTER TABLE fe_groups ADD COLUMN IF NOT EXISTS passkey_enforcement varchar(20) NOT NULL DEFAULT 'off';

-- nr_passkeys_fe: credential storage (varbinary + blob columns)
CREATE TABLE IF NOT EXISTS tx_nrpasskeysfe_credential (
    uid int(11) unsigned NOT NULL AUTO_INCREMENT,
    pid int(11) unsigned NOT NULL DEFAULT 0,
    tstamp int(11) unsigned NOT NULL DEFAULT 0,
    crdate int(11) unsigned NOT NULL DEFAULT 0,
    deleted tinyint(4) unsigned NOT NULL DEFAULT 0,
    hidden tinyint(4) unsigned NOT NULL DEFAULT 0,
    fe_user int(11) unsigned NOT NULL DEFAULT 0,
    credential_id varbinary(1024) NOT NULL,
    public_key_cose blob NOT NULL,
    sign_count int(11) unsigned NOT NULL DEFAULT 0,
    user_handle varbinary(64) DEFAULT NULL,
    aaguid char(36) DEFAULT NULL,
    transports text DEFAULT NULL,
    label varchar(128) NOT NULL DEFAULT '',
    site_identifier varchar(255) NOT NULL DEFAULT '',
    storage_pid int(11) unsigned NOT NULL DEFAULT 0,
    created_at int(11) unsigned NOT NULL DEFAULT 0,
    last_used_at int(11) unsigned NOT NULL DEFAULT 0,
    revoked_at int(11) unsigned NOT NULL DEFAULT 0,
    revoked_by int(11) unsigned NOT NULL DEFAULT 0,
    PRIMARY KEY (uid),
    UNIQUE KEY credential_id (credential_id(255)),
    KEY fe_user (fe_user),
    KEY site_storage (site_identifier, storage_pid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- nr_passkeys_fe: recovery codes
CREATE TABLE IF NOT EXISTS tx_nrpasskeysfe_recovery_code (
    uid int(11) unsigned NOT NULL AUTO_INCREMENT,
    pid int(11) unsigned NOT NULL DEFAULT 0,
    tstamp int(11) unsigned NOT NULL DEFAULT 0,
    crdate int(11) unsigned NOT NULL DEFAULT 0,
    deleted tinyint(4) unsigned NOT NULL DEFAULT 0,
    hidden tinyint(4) unsigned NOT NULL DEFAULT 0,
    fe_user int(11) unsigned NOT NULL DEFAULT 0,
    code_hash varchar(255) NOT NULL DEFAULT '',
    used_at int(11) unsigned NOT NULL DEFAULT 0,
    created_at int(11) unsigned NOT NULL DEFAULT 0,
    PRIMARY KEY (uid),
    KEY fe_user (fe_user)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Passkey management page (login-restricted, hidden from nav)
-- fe_group=-2 means "show at any login" (any authenticated fe_user)
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, sorting, title, slug, doktype, fe_group, is_siteroot, hidden, deleted, perms_userid, perms_groupid, perms_user, perms_group, perms_everybody, nav_hide)
VALUES (110, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 9300, 'My Passkeys', '/my-passkeys', 1, '-2', 0, 0, 0, 1, 1, 31, 27, 1, 1);

-- Passkey management plugin on that page
INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, sorting, CType, header, header_layout, colPos, hidden, deleted)
VALUES (444, 110, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 256, 'nrpasskeysfe_passkeymanagement', 'Manage Your Passkeys', 100, 0, 0, 0);
