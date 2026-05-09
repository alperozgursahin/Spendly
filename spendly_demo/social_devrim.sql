-- 1. PROFILES TABLOSUNA USERNAME EKLENMESI
ALTER TABLE profiles ADD COLUMN username TEXT UNIQUE;

-- Varolan profilere benzersiz bir username uret (Geçici çözüm)
UPDATE profiles SET username = 'user_' || substr(id::text, 1, 8) WHERE username IS NULL;

-- 2. FRIENDSHIPS TABLOSU
CREATE TABLE friendships (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id1 UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  user_id2 UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(user_id1, user_id2),
  CHECK (user_id1 != user_id2)
);

-- RLS for Friendships
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their friendships"
  ON friendships FOR SELECT
  USING (auth.uid() = user_id1 OR auth.uid() = user_id2);

CREATE POLICY "Users can create friendships"
  ON friendships FOR INSERT
  WITH CHECK (auth.uid() = user_id1);

CREATE POLICY "Users can update their friendship status"
  ON friendships FOR UPDATE
  USING (auth.uid() = user_id1 OR auth.uid() = user_id2);

CREATE POLICY "Users can delete their friendships"
  ON friendships FOR DELETE
  USING (auth.uid() = user_id1 OR auth.uid() = user_id2);


-- 3. DIRECT MESSAGES TABLOSU
CREATE TABLE direct_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  receiver_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  message TEXT NOT NULL,
  read_status BOOLEAN DEFAULT false NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS for Direct Messages
ALTER TABLE direct_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their messages"
  ON direct_messages FOR SELECT
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can send messages"
  ON direct_messages FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update read status of their received messages"
  ON direct_messages FOR UPDATE
  USING (auth.uid() = receiver_id);

-- Gerekli indexler
CREATE INDEX idx_friendships_user1 ON friendships(user_id1);
CREATE INDEX idx_friendships_user2 ON friendships(user_id2);
CREATE INDEX idx_dm_participants ON direct_messages(sender_id, receiver_id);

-- Tablolarda realtime yayınlamak icin
alter publication supabase_realtime add table friendships;
alter publication supabase_realtime add table direct_messages;
