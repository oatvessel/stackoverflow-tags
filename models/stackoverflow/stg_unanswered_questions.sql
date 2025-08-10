select
    id as question_id,
    creation_date,
    date_trunc(date(creation_date), month) as month,
    tags
from 
    {{ source('stackoverflow', 'posts_questions') }}
where creation_date is not null
  and tags is not null
  and (answer_count = 0 or accepted_answer_id is null)
