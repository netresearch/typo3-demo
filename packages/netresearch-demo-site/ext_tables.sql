-- Posts the social webhook test receiver accepted
-- (Classes/Middleware/SocialWebhookTestReceiver.php). uid, pid, crdate and
-- tstamp come from the TCA ctrl section.
CREATE TABLE tx_netresearchdemosite_social_webhook_receipt (
    platform varchar(64) DEFAULT '' NOT NULL,
    post_text mediumtext,
    publish_at int(11) unsigned DEFAULT '0' NOT NULL,
    artifact_uid int(11) unsigned DEFAULT '0' NOT NULL,
    job_uid int(11) unsigned DEFAULT '0' NOT NULL,
    source_url text,
    payload mediumtext
);
