
        --  *** SOCIAL MEDIA PROJECT *** --
        
--     ** OBJECTIVE QUESTIONS **  --

-- 1.Are there any tables with duplicate or missing null values? If so, how would you handle them?

 -- comments table duplicate checking
select distinct photo_id from comments;
select photo_id from comments;

select distinct user_id from comments;
select  user_id from comments;

select distinct id from comments;
select  id from comments;

-- follows table duplicate checking
select follower_id from follows;
select distinct follower_id  from follows;

select followee_id  from follows;
select distinct followee_id  from follows;

-- likes table duplicate checking
select user_id from likes;
select  distinct  user_id from likes;

select photo_id from likes;
select  distinct  photo_id from likes;

-- photo_tags table duplicate checking
select photo_id from photo_tags;
select distinct photo_id from photo_tags;

select tag_id from photo_tags;
select distinct tag_id from photo_tags;

-- photos table duplicate checking

select id from photos;
select distinct id from photos;

select image_url from photos;
select distinct image_url from photos;

select user_id from photos;
select distinct user_id from photos;

-- tags table duplicate checking
select id from tags;
select distinct id from tags;

-- users table duplicate checking 
select id from users;
select distinct id from users;

select username from users;
select distinct username from users;


-- comments table null checking
select distinct comment_text,user_id,photo_id,created_at,comment_text  from comments where comment_text is null ;
select distinct comment_text,user_id,photo_id,created_at  from comments where comment_text is not null ;
select distinct comment_text,user_id,photo_id,created_at  from comments where user_id is null;
select distinct comment_text,user_id,photo_id,created_at  from comments where user_id is not null;
select distinct comment_text,user_id,photo_id,created_at  from comments where photo_id is null;
select distinct comment_text,user_id,photo_id,created_at  from comments where photo_id is not null;

-- follows table null checking
select * from follows where follower_id is  null;
select * from follows where followee_id is not  null;

-- likes  table null checking
select * from likes  where user_id is  null;

-- photo_tags table null checking
select * from photo_tags  where photo_id is  null;
select * from photo_tags  where tag_id is  null;

-- photos table null checking 
select * from photos where image_url is null;
select * from photos where user_id is null;

--  tags table null checking 
select * from tags where tag_name is null;

-- users table null checking 
select * from users where username is null;




-- 2.What is the distribution of user activity levels (e.g., number of posts, likes, comments) across the user base?

SELECT distinct u.id AS UserID,
    coalesce(l.like_count, 0) AS like_count,
    coalesce(c.comment_count, 0) AS comment_count,
    coalesce(p.photo_count, 0) AS photo_count
FROM 
    users u 
  left JOIN 
    (SELECT distinct user_id, count(*) AS like_count FROM  likes GROUP BY  user_id) l 
   ON u.id=l.user_id
  left JOIN (SELECT distinct user_id, count(distinct id) AS comment_count FROM comments GROUP BY user_id) c 
   ON c.user_id=u.id
  left JOIN (SELECT distinct user_id, count(distinct id) AS photo_count FROM photos GROUP BY user_id) p
   ON p.user_id=u.id
 ORDER BY like_count desc,comment_count desc,photo_count desc;
--  limit 20;
 
   
-- 3. Calculate the average number of tags per post (photo_tags and photos tables)
  
	 WITH count_of_tags AS (
      SELECT distinct p.id as PhotoID,count(t.id) AS tags_Count
      FROM photos p
      LEFT JOIN photo_tags pt 
          ON  p.id=pt.photo_id
	  LEFT JOIN tags t 
          ON  t.id=pt.tag_id
	  GROUP BY p.id)
      
		SELECT 
        round(AVG(tags_count)) AS avg_tags_per_post
        FROM count_of_tags AS tag_counts;

	
-- 4. Identify the top users with the highest engagement rates (likes, comments) on their posts and rank them.

        WITH cte AS(
          SELECT distinct u.id as UserID,username,
                 coalesce(count_of_likes+count_of_comments,0) AS total_likes_comments,coalesce(count_of_posts,0) as count_of_posts
                 -- dense_rank() over(order by count_of_likes+count_of_comments desc) AS engagement_rank
		  FROM users u 
		   left JOIN 
          (SELECT distinct user_id,
                  count(*) AS count_of_likes
          FROM likes
          GROUP BY user_id) a 
            ON a.user_id=u.id
          left JOIN
          (SELECT distinct user_id,
                  count(*) AS count_of_comments
          FROM comments
          GROUP BY user_id) b 
            ON b.user_id=u.id
            left join 
            (select distinct user_id,count(*) as count_of_posts
              from photos  
              group by user_id
              having count(*)<>0) c 
              on u.id=c.user_id),
              table2 as (
	      SELECT UserID,username,
                 total_likes_comments,count_of_posts
          FROM cte
           WHERE count_of_posts<>0)
           select UserID,username,total_likes_comments,count_of_posts,
               dense_rank() over(order by total_likes_comments desc) AS engagement_rank
               from table2
          ;
          

-- 5.Which users have the highest number of followers and followings?

WITH FollowersCount AS (
    SELECT 
        distinct follower_id AS user_id,
        COUNT(  follower_id) AS num_followers
    FROM follows
    GROUP BY follower_id),

FollowingsCount AS (
    SELECT 
       distinct followee_id AS user_id,
        COUNT( followee_id) AS num_followings
    FROM follows
    GROUP BY followee_id),

UserStats AS (
    SELECT 
          distinct u.id,
        coalesce(fc.num_followers, 0) AS num_followers,
        coalesce(fgc.num_followings, 0) AS num_followings
    FROM users u
           LEFT JOIN FollowersCount fc 
                    ON u.id = fc.user_id
		   LEFT JOIN FollowingsCount fgc 
					ON u.id = fgc.user_id),

MaxCounts AS (
    SELECT 
        MAX(num_followers) AS max_followers,
        MAX(num_followings) AS max_followings
    FROM UserStats),

TopUsers AS (
    SELECT 
        us.id,
        us.num_followers,
        us.num_followings
    FROM UserStats us
		CROSS JOIN MaxCounts mc
    WHERE us.num_followers = mc.max_followers
         OR us.num_followings = mc.max_followings),
results as (
SELECT 
    id,
    num_followers,
    num_followings
FROM TopUsers
order by num_followings asc)

  -- NOTE: BEFORE RUNNING THE BELOW QUERIES COMMENT OUT ANY ONE QUERY TO GET SEPARATE OUTPUTS
  
--   -- # users having the highest no of followers #---
  SELECT  id,num_followers,num_followings 
  FROM results
  WHERE num_followers IN (SELECT max(num_followers) FROM results)
  limit 10
  ; 
  #  users having the highest no of followings #---
SELECT distinct id,num_followers,num_followings 
FROM results
WHERE num_followings IN(SELECT max(num_followings) FROM results)
;


-- 6.Calculate the average engagement rate (likes, comments) per post for each user

    WITH postlikes AS (
     SELECT distinct photo_id,
            count(user_id) AS like_count
	 FROM likes 
     GROUP BY photo_id),
     
	postcomments AS (
     SELECT distinct photo_id,
            count(user_id) AS comment_count
	 FROM comments 
     GROUP BY photo_id),
     
	Total_likes_n_comments AS (
	  SELECT distinct p.id AS photo_id,
                coalesce(pl.like_count, 0) AS like_count,
	            coalesce(pc.comment_count, 0) AS comment_count,
				coalesce(pl.like_count, 0) + coalesce(pc.comment_count, 0) AS total_engagement
      FROM photos p
				LEFT JOIN postlikes pl ON p.id=pl.photo_id
				LEFT JOIN postcomments pc ON p.id=pc.photo_id),
      
	user_engagement AS (
      SELECT distinct p.user_id,
			 round(avg(total_engagement),2) AS avg_engagement_rate
      FROM Total_likes_n_comments tc
			JOIN photos p 
				ON p.id=tc.photo_id
		GROUP BY  user_id)
        
	SELECT distinct u.id AS user_id,
           username,
           avg_engagement_rate
	FROM users u
         JOIN user_engagement ue
                 ON u.id=ue.user_id
	ORDER BY avg_engagement_rate desc;
    
  
--     7. Get the list of users who have never liked any post (users and likes tables)

   SELECT distinct u.id as userid,
           username
   FROM   users u
       LEFT JOIN likes l
               ON u.id = l.user_id 
   WHERE l.user_id is null;
   
   
   -- 8.How can you leverage user-generated content (posts, hashtags,photo tags) to create more personalized and engaging ad campaigns?
   
WITH HashtagEngagement AS (
    SELECT 
        distinct u.id AS user_id,
        u.username,
        COUNT(distinct h.tag_id) AS hashtag_engagement
    FROM users u
	JOIN 
        photos p ON p.user_id = u.id
    JOIN 
        photo_tags h ON p.id = h.photo_id
    GROUP BY u.id, u.username),

PhotoTagEngagement AS (
    SELECT 
        distinct u.id AS user_id,
        u.username,
        tag_name,
        COUNT(pt.photo_id) AS photo_tag_engagement
    FROM users u
    JOIN 
        photos p ON u.id = p.user_id
    JOIN 
        photo_tags pt ON p.id = pt.photo_id
	JOIN 
          tags t   on t.id=pt.tag_id
    GROUP BY u.id, u.username,tag_name)

SELECT 
  distinct  u.id AS user_id,
    u.username, tag_name,
    COALESCE(he.hashtag_engagement, 0) AS hashtag_engagement,
    COALESCE(pte.photo_tag_engagement, 0) AS photo_tag_engagement,
    (COALESCE(he.hashtag_engagement, 0) + COALESCE(pte.photo_tag_engagement, 0)) AS total_engagement
FROM 
    users u
LEFT JOIN 
    HashtagEngagement he ON u.id = he.user_id
LEFT JOIN 
    PhotoTagEngagement pte ON u.id = pte.user_id
ORDER BY 
    total_engagement DESC;


-- 9.Are there any correlations between user activity levels and specific
-- content types (e.g., photos, videos, reels)? How can this
-- information guide content creation and curation strategies?

   -- used this output to calculate correlation in excel
   with likescount as (
    SELECT distinct user_id,count(*) AS num_of_likes FROM likes
    GROUP BY user_id),
    
commentscount as (
    SELECT user_id,count(id) AS num_of_comments FROM comments
    GROUP BY user_id),

phototagscount as (
    SELECT u.id,count(tag_id) AS num_of_phototags
    FROM photos p
    JOIN photo_tags pt ON p.id=pt.photo_id
    JOIN users u  ON u.id=p.user_id
    GROUP BY id)
    
SELECT u.id as UserID,
       coalesce(num_of_likes,0) num_of_likes,
	   coalesce(num_of_comments,0) num_of_comments,
       coalesce(num_of_phototags,0)num_of_phototags
FROM users u
LEFT JOIN 
    likescount l ON u.id=l.user_id
LEFT JOIN 
    commentscount c ON u.id=c.user_id
LEFT join 
    phototagscount  p ON u.id=p.id;
   
   
--   10. Calculate the total number of likes, comments, and photo tags for each user

     --   same as 9th
with likescount as (
    SELECT distinct user_id,count(*) AS num_of_likes FROM likes
    GROUP BY user_id),
    
commentscount as (
    SELECT user_id,count(id) AS num_of_comments FROM comments
    GROUP BY user_id),

phototagscount as (
    SELECT u.id,count(tag_id) AS num_of_phototags
    FROM photos p
    JOIN photo_tags pt ON p.id=pt.photo_id
    JOIN users u  ON u.id=p.user_id
    GROUP BY id)
    
SELECT u.id as UserID,
       coalesce(num_of_likes,0) num_of_likes,
	   coalesce(num_of_comments,0) num_of_comments,
       coalesce(num_of_phototags,0)num_of_phototags
FROM users u
LEFT JOIN 
    likescount l ON u.id=l.user_id
LEFT JOIN 
    commentscount c ON u.id=c.user_id
LEFT join 
    phototagscount  p ON u.id=p.id;
    
    
    
   --  11. Rank users based on their total engagement (likes, comments, shares) over a month.

SELECT
    u.id,
    u.username,
    coalesce(sum(l.like_count), 0) AS total_likes,
    coalesce(sum(c.comment_count), 0) AS total_comments,
    coalesce(sum(l.like_count), 0) + coalesce(sum(c.comment_count), 0) AS total_engagement,
    dense_rank() over(order by coalesce(sum(l.like_count), 0) + coalesce(sum(c.comment_count), 0) desc) as UserRank
FROM users u
LEFT JOIN (
    SELECT
        user_id,
        count(*) AS like_count
    FROM likes
    WHERE MONTH(created_at) = 6 AND YEAR(created_at) = 2024 
    GROUP BY user_id) l 
        ON u.id = l.user_id
    LEFT JOIN (
    SELECT
        user_id,
        count(id) AS comment_count
    FROM comments
    WHERE MONTH(created_at) = 6 AND YEAR(created_at) = 2024 
    GROUP BY user_id) c 
        ON u.id = c.user_id
    GROUP BY u.id, u.username
    ORDER BY total_engagement DESC
    ;

    
--   12.  Retrieve the hashtags that have been used in posts with the highest average number of likes. 

WITH AverageLikes AS
(SELECT tag_name,avg(LikesCount) AS avg_likes
FROM photo_tags pt
JOIN tags t 
    ON t.id=pt.tag_id
JOIN 
(SELECT photo_id,count(user_id) AS LikesCount
FROM likes
GROUP BY photo_id) as A
   ON pt.photo_id=A.photo_id
GROUP BY tag_name)

SELECT tag_name,avg_likes
FROM AverageLikes 
ORDER BY avg_likes desc
LIMIT 10;



-- 13.Retrieve the users who have started following someone after being followed by that person

WITH cte AS
 (SELECT a.id,
    a.username AS follower, b.username AS followee
FROM
    follows f1
        LEFT JOIN
    follows f2 ON f1.follower_id = f2.followee_id
        AND f1.followee_id = f2.follower_id
        AND f1.created_at > f2.created_at
        LEFT JOIN
    users a ON a.id = f1.follower_id
        LEFT JOIN
    users b ON b.id = f1.followee_id
ORDER BY f1.created_at)

SELECT id,
    follower, COUNT(followee) AS count_of_followee
FROM
    cte
GROUP BY id, follower
limit 10
;


 
     --  ** SUBJECTIVE QUESTIONS ** --
     
     
-- 1.Based on user engagement and activity levels, which users would you consider the most loyal or valuable? How would you reward or
-- incentivize these users?

with
Likes AS (
    SELECT user_id, COUNT(*) AS like_count FROM likes
    GROUP BY user_id),
    
Posts AS (
    SELECT user_id, COUNT(*) AS post_count FROM photos
    GROUP BY user_id),
Comments AS (
    SELECT user_id, COUNT(*) AS comment_count FROM comments
    GROUP BY user_id),
Followers AS (
    SELECT followee_id AS user_id, COUNT(*) AS follower_count FROM follows
    GROUP BY followee_id)
    SELECT 
    id,
    username,
    COALESCE(p.post_count, 0) AS post_count,COALESCE(l.like_count, 0) AS like_count,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(f.follower_count, 0) AS follower_count,
    (COALESCE(p.post_count, 0) + COALESCE(l.like_count, 0) + COALESCE(c.comment_count, 0) + COALESCE(f.follower_count, 0))
    AS user_total_engagement
FROM users u JOIN Posts p ON u.id = p.user_id
LEFT JOIN Likes l ON u.id = l.user_id
LEFT JOIN Comments c ON u.id = c.user_id
LEFT JOIN Followers f ON u.id = f.user_id
ORDER BY user_total_engagement DESC
limit 10;



-- 3.Which hashtags or content topics have the highest engagement rates? How can this information guide content strategy and ad campaigns?

SELECT
    t.tag_name,
    COUNT(DISTINCT p.id) AS num_photos,
    COUNT(DISTINCT l.user_id) AS num_likes,
    COUNT(DISTINCT c.id) AS num_comments
FROM tags t
LEFT JOIN photo_tags pt ON t.id = pt.tag_id
LEFT JOIN photos p ON pt.photo_id = p.id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY t.tag_name
ORDER BY num_likes DESC, num_comments DESC, num_photos DESC;


-- 5.Based on follower counts and engagement rates, which users would be ideal candidates for influencer marketing campaigns?
-- How would you approach and collaborate with these influencers?

WITH Follwers AS (
    SELECT
        f.followee_id AS user_id,
        COUNT(f.follower_id) AS follower_count
    FROM follows f
    GROUP BY f.followee_id
),
total_likescomments AS (
    SELECT
        p.user_id,
        COUNT(DISTINCT l.user_id) AS total_likes,
        COUNT(DISTINCT c.id) AS total_comments
    FROM photos p
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id),
cte AS (
    SELECT
        u.id,
        u.username,
        f.follower_count,
        coalesce(t.total_likes, 0) AS total_likes,
        coalesce(t.total_comments, 0) AS total_comments,
        round((coalesce(t.total_likes, 0) + coalesce(t.total_comments, 0)) / coalesce(f.follower_count, 1),2)AS engagement_rate
    FROM users u
    LEFT JOIN Follwers f ON u.id = f.user_id
    LEFT JOIN total_likescomments t ON u.id = t.user_id)
SELECT
    id AS user_id,
    username,
    follower_count,
    total_likes,
    total_comments,
    engagement_rate
FROM cte
ORDER BY engagement_rate DESC, follower_count DESC
LIMIT 10;








 

