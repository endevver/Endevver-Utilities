-- Movable Type Database Orphan Purge SQL --
--
-- AUTHOR: Jay Allen, Endevver LLC 
-- URL:    http://github.com/endevver/Endevver-Utilities/blob/master/mt_orphan_purge.sql
--
-- DESCRIPTION
--
-- This script is intended to be used to purge orphaned
-- records from a Movable Type database powered by MySQL 5.0+
-- 
-- Please note that this script was written for a specific client after a
-- significant amount of inspection and testing and it may not apply cleanly
-- to your database.
--
-- If you want to use this script, you should either be sure that you've done
-- the same due diligence we did in creating it or you should consult with
-- us first.
--
-- If you decide to forge ahead like the Brave SQL Soldier we know you are,
-- we strongly recommend that you replace the phrase "not apply cleanly" in
-- the sentence before last with the phrase "completely destroy beyond repair"
-- in order to get into the proper frame of mind.
--
-- Have fun!

### HELPER VIEWS AND STORE PROCEDURES ###

-- EXAMPLE: select * from table_counts;
DROP VIEW IF EXISTS table_counts;
CREATE VIEW table_counts AS
     SELECT TABLE_NAME as tbl, TABLE_ROWS as rows
       FROM information_schema.tables
      WHERE TABLE_SCHEMA = database(); 

DELIMITER $$

-- SYNTAX:  purge_orphans( PARENT_TABLE, PARENT_PRIMARY_KEY, CHILD_TABLE, CHILD_FOREIGN_KEY );
-- EXAMPLE: CALL purge_orphaned_meta('mt_blog', 'blog_id', 'mt_comment', 'comment_blog_id' );
DROP PROCEDURE IF EXISTS purge_orphans$$
CREATE PROCEDURE purge_orphans
    (
        IN in_parent_tbl  varchar(255),
        IN in_parent_key  varchar(255),
        IN in_child_tbl   varchar(40),
        IN in_child_pfkey varchar(255)
    )
BEGIN
    DECLARE l_sql varchar(4000);
    SET l_sql=CONCAT_ws(' ',
        'DELETE FROM', in_child_tbl,
        'WHERE', in_child_pfkey, '> 0 AND', in_child_pfkey, 'NOT IN',
        '(SELECT', in_parent_key, 'FROM', in_parent_tbl, ')' );
    -- Alternate: SELECT asset_blog_id
    --              FROM mt_asset LEFT JOIN mt_blog ON asset_blog_id = blog_id
    --             WHERE asset_blog_id != 0 and blog_id = NULL;
    SET @sql = l_sql;
    PREPARE s1 FROM @sql;
    EXECUTE s1;
    select in_child_tbl as 'Table', row_count() as 'Records deleted';
    DEALLOCATE PREPARE s1;
END$$

-- SYNTAX:    purge_orphaned_meta( OBJECT_TYPE )
-- EXAMPLE: CALL purge_orphaned_meta('blog')
DROP PROCEDURE IF EXISTS purge_orphaned_meta$$
CREATE PROCEDURE purge_orphaned_meta
    (
        IN in_type varchar(255)
    )
BEGIN
    DECLARE l_sql       varchar(4000);
    DECLARE l_obj_tbl   varchar(40);
    DECLARE l_obj_key   varchar(40);
    DECLARE l_meta_tbl  varchar(40);
    DECLARE l_meta_key  varchar(40);
    SET l_obj_tbl  = CONCAT_ws( '_', 'mt',      in_type);
    SET l_obj_key  = CONCAT_ws( '_', in_type,   'id');
    SET l_meta_tbl = CONCAT_ws('_',  l_obj_tbl, 'meta');
    SET l_meta_key = CONCAT_ws('_',  in_type,   'meta', l_obj_key);
    SET l_sql      = CONCAT_ws(' ',
        'DELETE FROM', l_meta_tbl,
        'WHERE', l_meta_key, '> 0',
        'AND', l_meta_key, 'NOT IN (SELECT', l_obj_key, 'FROM', l_obj_tbl, ')'
    );
    SET @sql = l_sql;
    PREPARE s1 FROM @sql;
    EXECUTE s1;
    select l_meta_tbl as 'Table', row_count() as 'Records deleted';
    DEALLOCATE PREPARE s1;
END$$

DELIMITER ;

### START OF FUNCTIONAL SQL STATEMENTS ###

select * from table_counts;

### BLOG CHILDREN ###

CALL purge_orphans('mt_blog',       'blog_id',      'mt_asset',                 'asset_blog_id'                         ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_association',           'association_blog_id'                   ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_bob_job',               'bob_job_blog_id'                       ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_category',              'category_blog_id'                      ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_comment',               'comment_blog_id'                       ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_cropper_prototypes',    'cropper_prototypes_blog_id'            ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_entry',                 'entry_blog_id'                         ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_featured',              'featured_blog_id'                      ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_field',                 'field_blog_id'                         ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_fileinfo',              'fileinfo_blog_id'                      ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_ipbanlist',             'ipbanlist_blog_id'                     ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_log',                   'log_blog_id'                           ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_notification',          'notification_blog_id'                  ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_objectasset',           'objectasset_blog_id'                   ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_objecttag',             'objecttag_blog_id'                     ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_permission',            'permission_blog_id'                    ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_placement',             'placement_blog_id'                     ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_pub_batch',             'pub_batch_blog_id'                     ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_reblog_data',           'reblog_data_blog_id'                   ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_reblog_sourcefeed',     'reblog_sourcefeed_blog_id'             ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_squeeze_children',      'squeeze_children_blog_id'              ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_squeeze_homepages',     'squeeze_homepages_blog_id'             ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_tbping',                'tbping_blog_id'                        ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_template',              'template_blog_id'                      ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_templatemap',           'templatemap_blog_id'                   ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_touch',                 'touch_blog_id'                         ) \p;
CALL purge_orphans('mt_blog',       'blog_id',      'mt_trackback',             'trackback_blog_id'                     ) \p;


### ENTRY CHILDREN ###

CALL purge_orphans('mt_entry',      'entry_id',     'mt_checkbox',               'checkbox_entry_id'                    ) \p;
CALL purge_orphans('mt_entry',      'entry_id',     'mt_checkbox_fields',        'checkbox_fields_entry_id'             ) \p;
CALL purge_orphans('mt_entry',      'entry_id',     'mt_comment',                'comment_entry_id'                     ) \p;
CALL purge_orphans('mt_entry',      'entry_id',     'mt_comment',                'comment_promoted_to_entry_id'         ) \p;
CALL purge_orphans('mt_entry',      'entry_id',     'mt_continuedtext_fields',   'continuedtext_fields_entry_id'        ) \p;
CALL purge_orphans('mt_entry',      'entry_id',     'mt_featured_entry',         'featured_entry_entry_id'              ) \p;
CALL purge_orphans('mt_entry',      'entry_id',     'mt_fileinfo',               'fileinfo_entry_id'                    ) \p;
CALL purge_orphans('mt_entry',      'entry_id',     'mt_placement',              'placement_entry_id'                   ) \p;
CALL purge_orphans('mt_entry',      'entry_id',     'mt_rating',                 'rating_entry_id'                      ) \p;
CALL purge_orphans('mt_entry',      'entry_id',     'mt_ratingparticipant',      'ratingparticipant_entry_id'           ) \p;
CALL purge_orphans('mt_entry',      'entry_id',     'mt_ratingvote',             'ratingvote_entry_id'                  ) \p;
CALL purge_orphans('mt_entry',      'entry_id',     'mt_reblog_data',            'reblog_data_entry_id'                 ) \p;
CALL purge_orphans('mt_entry',      'entry_id',     'mt_squeeze_position_stack', 'squeeze_position_stack_entry_id'      ) \p;
CALL purge_orphans('mt_entry',      'entry_id',     'mt_trackback',              'trackback_entry_id'                   ) \p;


### COMMENT CHILDREN ###

CALL purge_orphans('mt_comment',    'comment_id',   'mt_commentfields',         'commentfields_comment_id'              ) \p;


### ASSET CHILDREN ###

CALL purge_orphans('mt_asset',      'asset_id',     'mt_cropper_prototypemaps', 'cropper_prototypemaps_asset_id'        ) \p;
CALL purge_orphans('mt_asset',      'asset_id',     'mt_cropper_prototypemaps', 'cropper_prototypemaps_cropped_asset_id') \p;
CALL purge_orphans('mt_asset',      'asset_id',     'mt_objectasset',           'objectasset_asset_id'                  ) \p;


### CATEGORY CHILDREN ###

CALL purge_orphans('mt_category',   'category_id',  'mt_fileinfo',              'fileinfo_category_id'                  ) \p;
CALL purge_orphans('mt_category',   'category_id',  'mt_placement',             'placement_category_id'                 ) \p;
CALL purge_orphans('mt_category',   'category_id',  'mt_reblog_sourcefeed',     'reblog_sourcefeed_category_id'         ) \p;
CALL purge_orphans('mt_category',   'category_id',  'mt_trackback',             'trackback_category_id'                 ) \p;


### TEMPLATE CHILDREN ###

CALL purge_orphans('mt_template',   'template_id',  'mt_fileinfo',              'fileinfo_template_id'                  ) \p;
CALL purge_orphans('mt_template',   'template_id',  'mt_squeeze_homepages',     'squeeze_homepages_template_id'         ) \p;
CALL purge_orphans('mt_template',   'template_id',  'mt_templatemap',           'templatemap_template_id'               ) \p;


### MISCELLANEOUS OTHER CHILDREN ###

CALL purge_orphans('mt_cropper_prototypes', 'cropper_prototypes_id',    'mt_cropper_prototypemaps', 'cropper_prototypemaps_prototype_id') \p;
CALL purge_orphans('mt_ratingparticipant',  'ratingparticipant_id',     'mt_ratingvote',            'ratingvote_participant_id'         ) \p;
CALL purge_orphans('mt_tag',                'tag_id',                   'mt_objecttag',             'objecttag_tag_id'                  ) \p;
CALL purge_orphans('mt_templatemap',        'templatemap_id',           'mt_fileinfo',              'fileinfo_templatemap_id'           ) \p;
CALL purge_orphans('mt_trackback',          'trackback_id',             'mt_tbping',                'tbping_tb_id'                      ) \p;


### ABSTRACTED MAPPING TABLES ###
# While the following CAN be used for other classes, they are mostly used
# for entries and, in two cases, authors. We don't expect any missing authors
# but there's no harm in cleaning up.

DELETE FROM mt_objectasset
       WHERE objectasset_object_ds       = 'entry'
         AND objectasset_object_id       > 0
         AND objectasset_object_id       NOT IN (select entry_id from mt_entry) \p;

DELETE FROM mt_objecttag
      WHERE objecttag_object_datasource = 'entry'
        AND objecttag_object_id         > 0
        AND objecttag_object_id         NOT IN (select entry_id from mt_entry) \p;

DELETE FROM mt_objectscore
      WHERE objectscore_object_ds       = 'entry'
        AND objectscore_object_id       > 0
        AND objectscore_object_id       NOT IN (select entry_id from mt_entry) \p;

DELETE FROM mt_objectscore
      WHERE objectscore_object_ds       = 'author'
        AND objectscore_object_id       > 0
        AND objectscore_object_id       NOT IN (select author_id from mt_author) \p;

DELETE FROM mt_featured
      WHERE featured_object_type        = 'author'
        AND featured_object_id          > 0
        AND featured_object_id          NOT IN (select author_id from mt_author) \p;


### SPECIAL CASES ###
-- In the following cases, we don't delete the record because it's not a
-- dependent. Instead we simply remove the foreign key of orphaned records.

UPDATE mt_author
    SET   author_userpic_asset_id = NULL
    WHERE author_userpic_asset_id  > 0
      AND author_userpic_asset_id NOT IN (select asset_id from mt_asset) \p;

UPDATE mt_entry
    SET   entry_template_id = NULL
    WHERE entry_template_id > 0
      AND entry_template_id NOT IN (select template_id from mt_template) \p;


### META TABLE CLEANUP ###

CALL purge_orphaned_meta('blog') \p;
CALL purge_orphaned_meta('entry') \p;
CALL purge_orphaned_meta('comment') \p;
CALL purge_orphaned_meta('tbping') \p;
CALL purge_orphaned_meta('template') \p;
CALL purge_orphaned_meta('asset') \p;
CALL purge_orphaned_meta('category') \p;
CALL purge_orphaned_meta('profileevent') \p;


### END OF FUNCTIONAL SQL STATEMENTS ###
select * from table_counts;

### RAW SQL STATEMENTS ###

-- DELETE FROM mt_asset              WHERE asset_blog_id               > 0  AND asset_blog_id              NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_association        WHERE association_blog_id         > 0  AND association_blog_id        NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_bob_job            WHERE bob_job_blog_id             > 0  AND bob_job_blog_id            NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_category           WHERE category_blog_id            > 0  AND category_blog_id           NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_comment            WHERE comment_blog_id             > 0  AND comment_blog_id            NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_cropper_prototypes WHERE cropper_prototypes_blog_id  > 0  AND cropper_prototypes_blog_id NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_entry              WHERE entry_blog_id               > 0  AND entry_blog_id              NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_featured           WHERE featured_blog_id            > 0  AND featured_blog_id           NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_field              WHERE field_blog_id               > 0  AND field_blog_id              NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_fileinfo           WHERE fileinfo_blog_id            > 0  AND fileinfo_blog_id           NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_ipbanlist          WHERE ipbanlist_blog_id           > 0  AND ipbanlist_blog_id          NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_log                WHERE log_blog_id                 > 0  AND log_blog_id                NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_notification       WHERE notification_blog_id        > 0  AND notification_blog_id       NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_objectasset        WHERE objectasset_blog_id         > 0  AND objectasset_blog_id        NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_objecttag          WHERE objecttag_blog_id           > 0  AND objecttag_blog_id          NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_permission         WHERE permission_blog_id          > 0  AND permission_blog_id         NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_placement          WHERE placement_blog_id           > 0  AND placement_blog_id          NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_pub_batch          WHERE pub_batch_blog_id           > 0  AND pub_batch_blog_id          NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_reblog_data        WHERE reblog_data_blog_id         > 0  AND reblog_data_blog_id        NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_reblog_sourcefeed  WHERE reblog_sourcefeed_blog_id   > 0  AND reblog_sourcefeed_blog_id  NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_squeeze_children   WHERE squeeze_children_blog_id    > 0  AND squeeze_children_blog_id   NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_squeeze_homepages  WHERE squeeze_homepages_blog_id   > 0  AND squeeze_homepages_blog_id  NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_tbping             WHERE tbping_blog_id              > 0  AND tbping_blog_id             NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_template           WHERE template_blog_id            > 0  AND template_blog_id           NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_templatemap        WHERE templatemap_blog_id         > 0  AND templatemap_blog_id        NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_touch              WHERE touch_blog_id               > 0  AND touch_blog_id              NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_trackback          WHERE trackback_blog_id           > 0  AND trackback_blog_id          NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_checkbox                WHERE checkbox_entry_id               > 0 AND checkbox_entry_id               NOT IN (select entry_id from mt_entry);
-- DELETE FROM mt_checkbox_fields         WHERE checkbox_fields_entry_id        > 0 AND checkbox_fields_entry_id        NOT IN (select entry_id from mt_entry);
-- DELETE FROM mt_comment                 WHERE comment_entry_id                > 0 AND comment_entry_id                NOT IN (select entry_id from mt_entry);
-- DELETE FROM mt_comment                 WHERE comment_promoted_to_entry_id    > 0 AND comment_promoted_to_entry_id    NOT IN (select entry_id from mt_entry);
-- DELETE FROM mt_continuedtext_fields    WHERE continuedtext_fields_entry_id   > 0 AND continuedtext_fields_entry_id   NOT IN (select entry_id from mt_entry);
-- DELETE FROM mt_featured_entry          WHERE featured_entry_entry_id         > 0 AND featured_entry_entry_id         NOT IN (select entry_id from mt_entry);
-- DELETE FROM mt_fileinfo                WHERE fileinfo_entry_id               > 0 AND fileinfo_entry_id               NOT IN (select entry_id from mt_entry);
-- DELETE FROM mt_placement               WHERE placement_entry_id              > 0 AND placement_entry_id              NOT IN (select entry_id from mt_entry);
-- DELETE FROM mt_rating                  WHERE rating_entry_id                 > 0 AND rating_entry_id                 NOT IN (select entry_id from mt_entry);
-- DELETE FROM mt_ratingparticipant       WHERE ratingparticipant_entry_id      > 0 AND ratingparticipant_entry_id      NOT IN (select entry_id from mt_entry);
-- DELETE FROM mt_ratingvote              WHERE ratingvote_entry_id             > 0 AND ratingvote_entry_id             NOT IN (select entry_id from mt_entry);
-- DELETE FROM mt_reblog_data             WHERE reblog_data_entry_id            > 0 AND reblog_data_entry_id            NOT IN (select entry_id from mt_entry);
-- DELETE FROM mt_squeeze_position_stack  WHERE squeeze_position_stack_entry_id > 0 AND squeeze_position_stack_entry_id NOT IN (select entry_id from mt_entry);
-- DELETE FROM mt_trackback               WHERE trackback_entry_id              > 0 AND trackback_entry_id              NOT IN (select entry_id from mt_entry);
-- DELETE FROM mt_comment                 WHERE comment_parent_id               > 0 AND comment_parent_id              NOT IN (select comment_id from mt_comment);
-- DELETE FROM mt_commentfields           WHERE commentfields_comment_id        > 0 AND commentfields_comment_id       NOT IN (select comment_id from mt_comment);
-- DELETE FROM mt_cropper_prototypemaps  WHERE cropper_prototypemaps_asset_id          > 0 AND cropper_prototypemaps_asset_id          NOT IN (select asset_id from mt_asset);
-- DELETE FROM mt_cropper_prototypemaps  WHERE cropper_prototypemaps_cropped_asset_id  > 0 AND cropper_prototypemaps_cropped_asset_id  NOT IN (select asset_id from mt_asset);
-- DELETE FROM mt_objectasset            WHERE objectasset_asset_id                    > 0 AND objectasset_asset_id                    NOT IN (select asset_id from mt_asset);
-- DELETE FROM mt_fileinfo           WHERE fileinfo_category_id           > 0 AND fileinfo_category_id           NOT IN (select category_id from mt_category);
-- DELETE FROM mt_placement          WHERE placement_category_id          > 0 AND placement_category_id          NOT IN (select category_id from mt_category);
-- DELETE FROM mt_reblog_sourcefeed  WHERE reblog_sourcefeed_category_id  > 0 AND reblog_sourcefeed_category_id  NOT IN (select category_id from mt_category);
-- DELETE FROM mt_trackback          WHERE trackback_category_id          > 0 AND trackback_category_id          NOT IN (select category_id from mt_category);
-- DELETE FROM mt_fileinfo           WHERE fileinfo_template_id            > 0 AND fileinfo_template_id            NOT IN (select template_id from mt_template);
-- DELETE FROM mt_squeeze_homepages  WHERE squeeze_homepages_template_id   > 0 AND squeeze_homepages_template_id   NOT IN (select template_id from mt_template);
-- DELETE FROM mt_templatemap        WHERE templatemap_template_id         > 0 AND templatemap_template_id         NOT IN (select template_id from mt_template);
-- DELETE FROM mt_cropper_prototypemaps  WHERE cropper_prototypemaps_prototype_id  > 0 AND cropper_prototypemaps_prototype_id  NOT IN (select cropper_prototypes_id from mt_cropper_prototypes);
-- DELETE FROM mt_tag                    WHERE tag_n8d_id                          > 0 AND tag_n8d_id                          NOT IN (select tag_id                from mt_tag);
-- DELETE FROM mt_ratingvote             WHERE ratingvote_participant_id           > 0 AND ratingvote_participant_id           NOT IN (select ratingparticipant_id  from mt_ratingparticipant);
-- DELETE FROM mt_objecttag              WHERE objecttag_tag_id                    > 0 AND objecttag_tag_id                    NOT IN (select tag_id                from mt_tag);
-- DELETE FROM mt_fileinfo               WHERE fileinfo_templatemap_id             > 0 AND fileinfo_templatemap_id             NOT IN (select templatemap_id        from mt_templatemap);
-- DELETE FROM mt_tbping                 WHERE tbping_tb_id                        > 0 AND tbping_tb_id                        NOT IN (select trackback_id          from mt_trackback);
-- DELETE FROM mt_blog_meta          WHERE blog_meta_blog_id                   > 0 AND blog_meta_blog_id                   NOT IN (select blog_id from mt_blog);
-- DELETE FROM mt_entry_meta         WHERE entry_meta_entry_id                 > 0 AND entry_meta_entry_id                 NOT IN (select entry_id from mt_entry);
-- DELETE FROM mt_comment_meta       WHERE comment_meta_comment_id             > 0 AND comment_meta_comment_id             NOT IN (select comment_id from mt_comment);
-- DELETE FROM mt_tbping_meta        WHERE tbping_meta_tbping_id               > 0 AND tbping_meta_tbping_id               NOT IN (select tbping_id from mt_tbping);
-- DELETE FROM mt_template_meta      WHERE template_meta_template_id           > 0 AND template_meta_template_id           NOT IN (select template_id from mt_template);
-- DELETE FROM mt_asset_meta         WHERE asset_meta_asset_id                 > 0 AND asset_meta_asset_id                 NOT IN (select asset_id from mt_asset);
-- DELETE FROM mt_category_meta      WHERE category_meta_category_id           > 0 AND category_meta_category_id           NOT IN (select category_id from mt_category);
-- DELETE FROM mt_profileevent_meta  WHERE profileevent_meta_profileevent_id   > 0 AND profileevent_meta_profileevent_id   NOT IN (select profileevent_id from mt_profileevent);

### THINGS WE ARE NOT MODIFYING ###

/*
    The following fields are legacy, no longer used and are most likely already NULL.
        * mt_entry.entry_category_id

    mt_drupal_import_comments  drupal_import_comments_comment_id            mt_comment
    mt_drupal_import_comments  drupal_import_comments_foreign_commenter_id  mt_foreign_commenter
    mt_drupal_import_comments  drupal_import_comments_foreign_id            mt_foreign
    mt_drupal_import_comments  drupal_import_comments_foreign_parent_id     mt_foreign_parent
    mt_profile_field_bak       profile_field_id
    mt_profile_field_bak       profile_field_author_id
    mt_reblog_data             reblog_data_guid
    mt_ts_error                ts_error_funcid
    mt_ts_error                ts_error_jobid
    mt_ts_exitstatus           ts_exitstatus_jobid
    mt_ts_exitstatus           ts_exitstatus_funcid
    mt_ts_funcmap              ts_funcmap_funcid
    mt_ts_job                  ts_job_jobid
    mt_ts_job                  ts_job_funcid
    mt_ts_job                  ts_job_batch_id                              mt_batch
    profile_fields             fid
    profile_values             fid
    profile_values             uid
    role                       rid
    users                      uid
    users_roles                uid
    users_roles                rid
*/

### ALL TABLES IN DEV DB ###

/*
    mt_asset
    mt_asset_meta
    mt_association
    mt_author
    mt_author_meta
    mt_blog
    mt_blog_evanbackup
    mt_blog_meta
    mt_blog_relations
    mt_bob_job
    mt_category
    mt_category_meta
    mt_checkbox
    mt_checkbox_fields
    mt_comment
    mt_comment_meta
    mt_commentfields
    mt_config
    mt_continuedtext_fields
    mt_cropper_prototypemaps
    mt_cropper_prototypes
    mt_delete_log
    mt_drupal_import_comments
    mt_entry
    mt_entry_meta
    mt_entry_response
    mt_featured
    mt_featured_entry
    mt_field
    mt_fileinfo
    mt_id_to_jm_id
    mt_ipbanlist
    mt_log
    mt_notification
    mt_objectasset
    mt_objectscore
    mt_objecttag
    mt_permission
    mt_placement
    mt_plugindata
    mt_profile_field
    mt_profile_field_bak
    mt_profileevent
    mt_profileevent_meta
    mt_pub_batch
    mt_rating
    mt_ratingparticipant
    mt_ratingvote
    mt_reblog_data
    mt_reblog_sourcefeed
    mt_rebuildq_file
    mt_repost_entry
    mt_role
    mt_session
    mt_squeeze_children
    mt_squeeze_homepages
    mt_squeeze_position_stack
    mt_squeeze_positions
    mt_tag
    mt_tbping
    mt_tbping_meta
    mt_template
    mt_template_meta
    mt_templatemap
    mt_touch
    mt_trackback
    mt_ts_error
    mt_ts_exitstatus
    mt_ts_funcmap
    mt_ts_job
    profile_fields
    profile_values
    role
    table_counts
    users
    users_roles
*/
