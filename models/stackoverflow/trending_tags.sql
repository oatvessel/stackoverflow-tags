with monthly_tag_count as (
    select
        t.tag,
        tg.tag_description,
        q.month,
        count(*) as unanswered_question_count
    from 
        {{ ref('question_tag_bridge') }} t
    join 
        {{ ref('stg_unanswered_questions') }} q
        on t.question_id = q.question_id
    left join {{ ref('stg_tags') }} tg
        on t.tag = tg.tag
    group by q.month, t.tag, tg.tag_description
),

tag_growth as (
    select 
        mtc.month,
        mtc.tag,
        mtc.tag_description,
        mtc.unanswered_question_count,
        lag(mtc.unanswered_question_count) over (partition by mtc.tag order by mtc.month) as prev_month_count,
        mtc.unanswered_question_count - lag(mtc.unanswered_question_count) over (partition by mtc.tag order by mtc.month) as absolute_growth,
        safe_divide(
            mtc.unanswered_question_count - lag(mtc.unanswered_question_count) over (partition by mtc.tag order by mtc.month),
            lag(mtc.unanswered_question_count) over (partition by mtc.tag order by mtc.month)
        ) as growth_rate
    from monthly_tag_count mtc
),

ranked_tag_growth as (
    select
        tg.month,
        tg.tag,
        tg.tag_description,
        tg.unanswered_question_count,
        tg.prev_month_count,
        tg.absolute_growth,
        round(tg.growth_rate * 100, 2) as growth_rate_percent,
        rank() over (partition by tg.month order by tg.absolute_growth desc) as absolute_growth_rank,
        rank() over (partition by tg.month order by tg.growth_rate desc) as growth_rate_percent_rank
    from tag_growth tg
),

most_recent_month as (
    select max(month) as most_recent
    from ranked_tag_growth
),

previous_month as (
    select date_sub(most_recent, interval 1 month) as prev_month
    from most_recent_month
)

select
    rtg.month,
    rtg.tag,
    rtg.tag_description,
    rtg.unanswered_question_count,
    rtg.prev_month_count,
    rtg.absolute_growth,
    rtg.growth_rate_percent,
    rtg.absolute_growth_rank,
    rtg.growth_rate_percent_rank,
    case
        when rtg.month = (select most_recent from most_recent_month) then 'Most Recent Month'
        when rtg.month = (select prev_month from previous_month) then 'Previous Month'
        else 'Other Month'
    end as month_flag
from ranked_tag_growth rtg
where rtg.unanswered_question_count >= 5
order by rtg.month desc, rtg.growth_rate_percent desc
