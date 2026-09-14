-- Fixes a bug introduced by 20260914194938 (custom_categories_name_only).
--
-- That migration defaulted `emoji` to the empty string so a name-only insert
-- would succeed. It does not: the table carries
--     CHECK (length(emoji) >= 1 AND length(emoji) <= 16)
-- which an empty string fails, so every attempt to add a custom category came
-- back as a server error. Reproduced before writing this: inserting without an
-- emoji raised 23514 custom_categories_emoji_check.
--
-- The column is vestigial now -- nothing reads or writes it -- so the length
-- check guards nothing and is dropped. The default goes with it: leaving the
-- column NULL on new rows is honest about there being no emoji, where '' would
-- claim there is an empty one. Old rows keep whatever they had.

alter table public.custom_categories
  drop constraint if exists custom_categories_emoji_check;

alter table public.custom_categories
  alter column emoji drop default;
