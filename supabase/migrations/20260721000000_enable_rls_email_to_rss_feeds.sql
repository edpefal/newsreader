-- Corrige el hallazgo crítico "Table publicly accessible" (rls_disabled_in_public)
-- del Supabase Advisor: generated_feeds y feed_items no tenían RLS habilitado,
-- por lo que cualquiera con el anon key (embebido en el cliente distribuido)
-- podía leer/editar/borrar todas las filas directamente vía PostgREST.
--
-- El único acceso legítimo a estas tablas es desde las edge functions
-- (create-feed, inbound-email, feed), que usan SUPABASE_SERVICE_ROLE_KEY y
-- por lo tanto ignoran RLS. No hace falta ninguna policy permisiva: se
-- habilita RLS sin políticas para bloquear todo acceso directo vía
-- anon/authenticated, sin afectar a las edge functions.

alter table generated_feeds enable row level security;
alter table feed_items enable row level security;
