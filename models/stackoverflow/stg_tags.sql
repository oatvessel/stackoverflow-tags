select
    title as tag,
    body as tag_description
from 
    {{ source('stackoverflow', 'posts_tag_wiki') }}
where title is not null
    and body is not null
