-- Custom categories are name-only from now on. Users type an emoji into the
-- name if they want one, which is what they were doing anyway, so the separate
-- emoji field and the colour picker were two extra decisions for no gain.
--
-- The columns are kept rather than dropped: existing rows carry real values and
-- dropping them would throw that away irreversibly for a cosmetic change. They
-- simply stop being written, so they need defaults for a name-only insert to
-- succeed, and the NOT NULL is relaxed so an explicit null is not an error
-- either.

alter table public.custom_categories
  alter column emoji drop not null,
  alter column emoji set default '',
  alter column color_value drop not null,
  alter column color_value set default 0;
