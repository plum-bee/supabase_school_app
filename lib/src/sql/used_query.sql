-- Create a table for public professor
create table professor (
  id uuid references auth.users on delete cascade not null primary key,
  updated_at timestamp with time zone,
  username text unique,
  full_name text,
  avatar_url text,
  website text,

  constraint username_length check (char_length(username) >= 3)
);

-- Create table for subjects
create table subject (
  id serial primary key,
  name text unique,
  description text
);

-- Create junction table for professors and subjects
create table professor_subject (
  professor_id uuid references professor(id) on delete cascade,
  subject_id int references subject(id) on delete cascade,
  primary key (professor_id, subject_id)
);



-- Set up Row Level Security (RLS)
-- See https://supabase.com/docs/guides/auth/row-level-security for more details.
alter table professor
  enable row level security;

create policy "Public professor are viewable by everyone." on professor
  for select using (true);

create policy "Users can insert their own profile." on professor
  for insert with check (auth.uid() = id);

create policy "Users can update own profile." on professor
  for update using (auth.uid() = id);

-- Set up Row Level Security (RLS) for subjects
alter table subject
  enable row level security;

create policy "Subjects are viewable by everyone." on subject
  for select using (true);

-- Set up RLS for professor_subject
alter table professor_subject
  enable row level security;

create policy "Junction is viewable by everyone." on professor_subject
  for select using (true);

-- This trigger automatically creates a profile entry when a new user signs up via Supabase Auth.
-- See https://supabase.com/docs/guides/auth/managing-user-data#using-triggers for more details.
create function public.handle_new_user()
returns trigger as $$
begin
  insert into public.professor
 (id, full_name, avatar_url)
  values (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url');
  return new;
end;
$$ language plpgsql security definer;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Set up Storage!
insert into storage.buckets (id, name)
  values ('avatars', 'avatars');

-- Set up access controls for storage.
-- See https://supabase.com/docs/guides/storage#policy-examples for more details.
create policy "Avatar images are publicly accessible." on storage.objects
  for select using (bucket_id = 'avatars');

create policy "Anyone can upload an avatar." on storage.objects
  for insert with check (bucket_id = 'avatars');