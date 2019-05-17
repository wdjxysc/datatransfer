-- 校内通知数据迁移
-- 导出json
-- SET SESSION group_concat_max_len=102400;

-- 如果发布人是学校 则publisherId设为orgId
SELECT
GROUP_CONCAT(
	CONCAT_WS(
		'|',
		t3.personid,
		t3.name,
		CASE
		WHEN t4.user_type='1' THEN '1'
		WHEN t4.user_type='2' THEN '0'
		WHEN t4.user_type='3' THEN '2'
		ELSE t4.user_type END,
		case WHEN t2.status is null THEN '-1'
		else t2.status end,
		case WHEN t2.read_time is null THEN '-1'
		else t2.read_time end
	)
	) AS readers,
t1.news_id AS zhxy_id,
t1.read_flg AS readFlg,
(
CASE WHEN t1.read_flg = 1 THEN (
	SELECT GROUP_CONCAT( CONCAT_WS('|', t_temp_user.personid,'1','0','-1')) AS users
	FROM us_user t_temp_user
	LEFT JOIN us_user_info t_temp_user_info ON t_temp_user.user_id = t_temp_user_info.user_id
	where t_temp_user.school_id = t1.school_id and t_temp_user.user_type = '1'
	GROUP BY t_temp_user.school_id
)
else '' end
) AS allReaders,
-- publisherMsgCode 详细信息参考 智慧校园数据导入结构.doc
-- t6.platformCode AS publisherMsgCode,
CONCAT_WS('_', t6.loginPlatformCode, t6.platformCode) AS publisherMsgCode,
(
CASE
	WHEN t7.is_org_user = '1' THEN t6.orgaid
	ELSE t5.personid END
	)
 AS publisherId,
t5.name AS publisherName,
t1.title AS title,
t1.context AS content,
t1.introduction AS descrip,
t6.orgaid AS orgId,
t6.school_name AS orgName,
'3' AS orgType,
t1.publish_time AS publishDate,
'0' AS isTodo,
'0' AS needConfirm
FROM `news` t1
LEFT JOIN news_reader t2 ON t2.news_id = t1.news_id
LEFT JOIN us_user_info t3 ON t2.user_id = t3.user_id
LEFT JOIN us_user t4 ON t2.user_id = t4.user_id
LEFT JOIN us_user_info t5 ON t1.publish_user = t5.user_id
LEFT JOIN us_school t6 ON t6.school_id = t1.school_id
LEFT JOIN us_user t7 ON t1.publish_user = t7.user_id
WHERE t5.personid is not null
AND (t3.personid is not null or t1.read_flg = 1)
-- and t1.news_id = 1000149500006841
-- and t1.publish_time <= '2018-01-01 00:00:00'
GROUP BY t1.news_id
ORDER BY t1.news_id ASC



---------------------- 校内通知Start  ----------------------
-- 通知表
CREATE TABLE `news` (
  `news_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT 'id',
  `school_id` bigint(20) unsigned DEFAULT NULL COMMENT '所属学校',
  `type_id` varchar(20) DEFAULT NULL COMMENT '所属分类',
  `site_id` bigint(20) DEFAULT '0' COMMENT '站点ID',
  `title` varchar(200) DEFAULT NULL COMMENT '新闻标题',
  `title_style` varchar(100) DEFAULT NULL COMMENT '标题显示的颜色以及效果',
  `deputy_title` varchar(200) DEFAULT NULL COMMENT '副标题(关键词)',
  `context` mediumtext CHARACTER SET utf8mb4 COMMENT '内容',
  `publish_context` mediumtext COMMENT '签发人意见',
  `click_num` smallint(5) unsigned DEFAULT NULL COMMENT '点击数',
  `reply_flg` tinyint(3) unsigned DEFAULT NULL COMMENT '回复标志',
  `appraise_flg` tinyint(3) unsigned DEFAULT NULL COMMENT '评价标志',
  `reply_num` smallint(5) unsigned DEFAULT NULL COMMENT '回复（评论）数',
  `park_top` tinyint(3) unsigned DEFAULT NULL COMMENT '置顶标志',
  `top_time` datetime DEFAULT NULL COMMENT '置顶到期日期',
  `park_commend` tinyint(3) unsigned DEFAULT NULL COMMENT '推荐标志',
  `limit_in_out` tinyint(3) unsigned DEFAULT NULL COMMENT '内外网',
  `first_img` varchar(500) DEFAULT NULL COMMENT '第一张图片-自动缩略图',
  `auditing_status` tinyint(3) unsigned DEFAULT NULL COMMENT '审核状态',
  `source` varchar(200) DEFAULT NULL COMMENT '来源（没有则不要在详细页面显示）',
  `publish_user` bigint(20) unsigned DEFAULT NULL COMMENT '发布者',
  `publish_time` datetime DEFAULT NULL COMMENT '发布时间',
  `show_time` datetime DEFAULT NULL COMMENT '开始显示时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `read_flg` int(10) unsigned DEFAULT NULL COMMENT '实名签读情况',
  `display_flg` tinyint(3) unsigned DEFAULT NULL COMMENT '接受人是否公开显示',
  `publish_news_id` bigint(20) unsigned DEFAULT NULL COMMENT '同步发布的新闻ID',
  `del_flg` tinyint(3) unsigned DEFAULT NULL COMMENT '删除情况',
  `publish_del_flg` tinyint(3) unsigned DEFAULT '0' COMMENT '发布人操作标记',
  `action_status` tinyint(3) unsigned DEFAULT NULL COMMENT '工作流状态',
  `stu_class_list_id` varchar(200) DEFAULT NULL COMMENT '学生所属班级id',
  `par_class_list_id` varchar(200) DEFAULT NULL COMMENT '家长所属班级id',
  `dept_name` varchar(50) DEFAULT NULL COMMENT '教师部门名称',
  `introduction` varchar(1000) DEFAULT NULL COMMENT '简介',
  `yearly` varchar(50) DEFAULT NULL COMMENT '年度',
  `semester` varchar(10) DEFAULT NULL COMMENT '学期',
  `update_user_info` varchar(1000) DEFAULT NULL COMMENT '文章修改信息',
  `read_ratio` float(5,2) DEFAULT NULL COMMENT '阅读率',
  `read_end_flg` tinyint(3) unsigned DEFAULT '0' COMMENT '阅读期限开关(1表示开启0表示关闭)',
  `read_end_date` datetime DEFAULT NULL COMMENT '阅读期限日期',
  `parent_id` bigint(20) unsigned DEFAULT NULL COMMENT '跟踪回复了哪条news_id-暂时用于教师工作日志中',
  `remote_ip` varchar(25) DEFAULT NULL,
  `reward` smallint(6) DEFAULT '0',
  `last_reply_time` datetime DEFAULT NULL COMMENT '最后回复时间',
  `i1` int(11) DEFAULT NULL COMMENT '数字预留1-有说明',
  `i2` bigint(20) DEFAULT NULL COMMENT '数字预留2-阅读指导对应的推荐书籍',
  `i3` int(11) DEFAULT NULL COMMENT '数字预留3',
  `s1` varchar(50) DEFAULT NULL COMMENT '字符预留1-特殊字段（有说明）',
  `s2` varchar(50) DEFAULT NULL COMMENT '字符预留2-读书札记对应的书籍名称',
  `s3` varchar(50) DEFAULT NULL COMMENT '字符预留3-签发人(指定用户userId)',
  `s4` varchar(100) DEFAULT NULL COMMENT '字符预留4-文章源作者',
  `s5` varchar(200) DEFAULT NULL COMMENT '字符预留5 图片路径',
  `s6` varchar(200) DEFAULT NULL COMMENT '字符预留6 公文字号',
  `s7` varchar(200) DEFAULT NULL COMMENT '字符预留7 公文来文单位',
  `s8` varchar(200) DEFAULT NULL COMMENT '字符预留8 公文编号',
  `s9` varchar(200) DEFAULT NULL COMMENT '字符预留9 公文密级',
  `s10` varchar(200) DEFAULT NULL COMMENT '字符预留10 归档标志',
  `qttz` char(1) DEFAULT '0' COMMENT 'qttz-是否不需要登录就能查看',
  `appshow` int(11) DEFAULT '1' COMMENT '掌上校园显示标志',
  `app_icon` varchar(200) DEFAULT NULL COMMENT 'app缩略图',
  `app_content` mediumtext CHARACTER SET utf8mb4 COMMENT 'app内容-压缩图片的',
  `s3_name` varchar(36) DEFAULT NULL COMMENT '公文优化：签发人姓名',
  `m_user_names` varchar(200) DEFAULT NULL COMMENT '公文优化：主办人姓名',
  `u_user_names` varchar(200) DEFAULT NULL COMMENT '公文优化：承办人姓名',
  `b_user_names` varchar(400) DEFAULT NULL COMMENT '公文优化：办理人姓名',
  `s3_time` datetime DEFAULT NULL,
  PRIMARY KEY (`news_id`)
) ENGINE=InnoDB AUTO_INCREMENT=64 DEFAULT CHARSET=utf8;

-- 回复评论
CREATE TABLE `news_reply` (
  `reply_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `news_id` bigint(20) unsigned DEFAULT NULL COMMENT '所属新闻',
  `reply_user` bigint(20) unsigned DEFAULT NULL COMMENT '回复人-0 表示游客回复',
  `reply_context` mediumtext COMMENT '回复内容',
  `reply_time` datetime DEFAULT NULL COMMENT '回复时间',
  `reply_ip` varchar(50) DEFAULT NULL COMMENT '回复时的ip',
  `reply_title` varchar(100) DEFAULT NULL,
  `attaches` tinyint(4) DEFAULT '0',
  `is_hide_post` varchar(2) DEFAULT 'F',
  `is_best` varchar(2) DEFAULT 'F',
  `state` varchar(2) DEFAULT 'N',
  `update_time` datetime DEFAULT NULL,
  `i1` int(11) DEFAULT NULL,
  `i2` int(11) DEFAULT NULL,
  `s1` varchar(50) DEFAULT NULL,
  `s2` varchar(50) DEFAULT NULL,
  `s3` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`reply_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 阅读者
CREATE TABLE `news_reader` (
  `news_id` bigint(20) unsigned NOT NULL COMMENT '新闻id',
  `user_id` bigint(20) unsigned NOT NULL COMMENT '用户id',
  `school_id` bigint(20) unsigned NOT NULL COMMENT '学校id',
  `status` tinyint(3) unsigned DEFAULT NULL COMMENT '状态（0－未读 1－已读 2-删除 3-彻底删除）',
  `read_time` datetime DEFAULT NULL COMMENT '阅读时间',
  `i1` int(11) DEFAULT NULL,
  `i2` int(11) DEFAULT NULL,
  `s1` varchar(50) DEFAULT NULL,
  `s2` varchar(50) DEFAULT NULL,
  `s3` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`news_id`,`user_id`,`school_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
---------------------- 校内通知End    ----------------------