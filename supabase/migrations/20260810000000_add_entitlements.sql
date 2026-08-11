-- Tabla de estado de suscripción sincronizada desde Superwall (ver
-- openspec/changes/gate-daily-summary-behind-superwall-paywall). Es la
-- fuente de verdad que `summarize-articles` consulta antes de invocar a
-- Gemini -- el gate de la UI (SDK de Superwall) es solo una mejora de
-- experiencia, no el único candado.
--
-- Ausencia de fila = sin suscripción activa (no se siembra una fila en
-- `false` para cada usuario nuevo).
create table entitlements (
  user_id uuid primary key references auth.users (id) on delete cascade,
  is_active boolean not null default false,
  updated_at timestamptz not null default now()
);

alter table entitlements enable row level security;

-- El usuario solo puede leer su propia fila. `summarize-articles` usa el
-- cliente scoped al usuario (mismo `userClient` que ya usa para
-- `auth.getUser`) para esta consulta, apoyándose en esta policy en vez de
-- necesitar `service_role` para leer.
create policy entitlements_select_own on entitlements
  for select
  using (user_id = auth.uid());

-- Sin policy de insert/update para roles no privilegiados: solo
-- `service_role` (usado por `superwall-webhook`) puede escribir, porque
-- ignora RLS. Cualquiera con el anon/authenticated key no puede
-- auto-otorgarse una suscripción.
