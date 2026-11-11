-- Posts the social webhook test receiver accepted
-- (Classes/Middleware/SocialWebhookTestReceiver.php). pid, crdate and tstamp
-- come from the TCA ctrl section.
--
-- uid is declared here although TYPO3 derives it from TCA as well: the
-- entrypoint runs extension:setup before it flushes the caches, so on the
-- deploy that brings a new table the cached TCA of the previous release does
-- not know it yet, and the table is created from this file alone. Without uid
-- here it then lacks its primary key for good, because adding an
-- auto-increment column to an existing table fails as two separate statements.
-- data/seed-extensions.sql (step 3f) repairs a table created that way.
CREATE TABLE tx_netresearchdemosite_social_webhook_receipt (
    uid int(11) unsigned NOT NULL auto_increment,
    platform varchar(64) DEFAULT '' NOT NULL,
    post_text mediumtext,
    publish_at int(11) unsigned DEFAULT '0' NOT NULL,
    artifact_uid int(11) unsigned DEFAULT '0' NOT NULL,
    job_uid int(11) unsigned DEFAULT '0' NOT NULL,
    source_url text,
    payload mediumtext,

    PRIMARY KEY (uid)
);
