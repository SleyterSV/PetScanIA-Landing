-- PetScanIA identity, family, roles, campaigns and medical history schema.
-- Run this in Supabase SQL editor before enabling the production WhatsApp OTP flow.

create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text unique,
  country_code text,
  city text,
  avatar_url text,
  role text default 'user',
  has_accepted_terms boolean default false,
  phone_verified_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.user_roles (
  user_id uuid references auth.users(id) on delete cascade,
  role text not null check (role in ('pet_owner', 'vet', 'shelter', 'rescuer', 'admin')),
  status text not null default 'active',
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  primary key (user_id, role)
);

create table if not exists public.vet_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  license_number text,
  clinic_name text,
  city text,
  verification_status text default 'pending',
  verified_at timestamptz,
  created_at timestamptz default now()
);

create table if not exists public.family_groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz default now()
);

create table if not exists public.family_members (
  id uuid primary key default gen_random_uuid(),
  family_id uuid references public.family_groups(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'admin', 'member', 'viewer')),
  status text not null default 'active',
  can_edit_pets boolean default false,
  can_view_medical boolean default true,
  created_at timestamptz default now(),
  unique (family_id, user_id)
);

create table if not exists public.family_invites (
  id uuid primary key default gen_random_uuid(),
  family_id uuid references public.family_groups(id) on delete cascade,
  invited_by uuid references auth.users(id) on delete set null,
  phone text not null,
  role text not null default 'member',
  status text not null default 'pending',
  created_at timestamptz default now()
);

alter table public.pets
  add column if not exists family_id uuid references public.family_groups(id) on delete set null;

create table if not exists public.medical_records (
  id uuid primary key default gen_random_uuid(),
  family_id uuid references public.family_groups(id) on delete cascade,
  pet_id uuid null,
  pet_name text,
  created_by uuid references auth.users(id) on delete set null,
  created_by_name text,
  record_type text not null default 'consulta',
  title text not null,
  notes text,
  visit_date timestamptz default now(),
  verified_by_vet boolean default false,
  created_at timestamptz default now()
);

create table if not exists public.vet_access_codes (
  id uuid primary key default gen_random_uuid(),
  family_id uuid references public.family_groups(id) on delete cascade,
  created_by uuid references auth.users(id) on delete cascade,
  code text not null,
  status text not null default 'active',
  expires_at timestamptz not null,
  created_at timestamptz default now()
);

create table if not exists public.community_campaigns (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  category text not null,
  city text not null,
  district text,
  location text,
  date_label text,
  campaign_date timestamptz default now(),
  organizer text,
  description text,
  requirements text,
  image_url text,
  capacity integer default 0,
  reserved integer default 0,
  is_verified boolean default false,
  is_active boolean default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz default now()
);

create table if not exists public.community_campaign_reservations (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid references public.community_campaigns(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  status text default 'reserved',
  created_at timestamptz default now(),
  unique (campaign_id, user_id)
);

create table if not exists public.security_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  event_type text not null,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

create index if not exists idx_profiles_phone on public.profiles(phone);
create index if not exists idx_family_members_user on public.family_members(user_id);
create index if not exists idx_family_members_family on public.family_members(family_id);
create index if not exists idx_medical_records_family_date on public.medical_records(family_id, visit_date desc);
create index if not exists idx_campaigns_active_date on public.community_campaigns(is_active, campaign_date);

alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.vet_profiles enable row level security;
alter table public.family_groups enable row level security;
alter table public.family_members enable row level security;
alter table public.family_invites enable row level security;
alter table public.medical_records enable row level security;
alter table public.vet_access_codes enable row level security;
alter table public.community_campaigns enable row level security;
alter table public.community_campaign_reservations enable row level security;
alter table public.security_events enable row level security;

create policy "profiles own read" on public.profiles
  for select using (auth.uid() = id);
create policy "profiles own upsert" on public.profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);

create policy "roles own read" on public.user_roles
  for select using (auth.uid() = user_id);
create policy "roles own write" on public.user_roles
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "vet own profile" on public.vet_profiles
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "family visible to members" on public.family_groups
  for select using (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = id and fm.user_id = auth.uid() and fm.status = 'active'
    )
  );
create policy "family create authenticated" on public.family_groups
  for insert with check (auth.uid() = created_by);

create policy "members visible inside family" on public.family_members
  for select using (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = family_members.family_id
      and fm.user_id = auth.uid()
      and fm.status = 'active'
    )
  );
create policy "members own family write" on public.family_members
  for all using (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = family_members.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('owner', 'admin')
      and fm.status = 'active'
    )
  ) with check (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = family_members.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('owner', 'admin')
      and fm.status = 'active'
    )
    or exists (
      select 1 from public.family_groups fg
      where fg.id = family_members.family_id
      and fg.created_by = auth.uid()
    )
  );

create policy "invites family admins" on public.family_invites
  for all using (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = family_invites.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('owner', 'admin')
      and fm.status = 'active'
    )
  ) with check (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = family_invites.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('owner', 'admin')
      and fm.status = 'active'
    )
  );

create policy "medical visible to family" on public.medical_records
  for select using (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = medical_records.family_id
      and fm.user_id = auth.uid()
      and fm.can_view_medical = true
      and fm.status = 'active'
    )
  );
create policy "medical write by editors" on public.medical_records
  for insert with check (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = medical_records.family_id
      and fm.user_id = auth.uid()
      and fm.can_edit_pets = true
      and fm.status = 'active'
    )
  );

create policy "vet codes family admins" on public.vet_access_codes
  for all using (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = vet_access_codes.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('owner', 'admin')
      and fm.status = 'active'
    )
  ) with check (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = vet_access_codes.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('owner', 'admin')
      and fm.status = 'active'
    )
  );

create policy "campaigns public read" on public.community_campaigns
  for select using (is_active = true);
create policy "campaign reservations own" on public.community_campaign_reservations
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "security events own" on public.security_events
  for select using (auth.uid() = user_id);
create policy "security events own insert" on public.security_events
  for insert with check (auth.uid() = user_id);
