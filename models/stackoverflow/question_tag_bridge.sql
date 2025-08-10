with posts as (
    select * from {{ ref('stg_unanswered_questions') }}
)

select
    question_id,
    date_trunc(date(creation_date), month) as month,
    tag
from posts,
unnest(split(tags, '|')) as tag
