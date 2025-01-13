/*
  # Create Crypto Transactions Schema

  1. New Tables
    - `crypto_transactions`
      - `id` (uuid, primary key)
      - `user_id` (uuid, foreign key to auth.users)
      - `crypto_name` (text)
      - `quantity` (numeric)
      - `purchase_price` (numeric)
      - `total_value` (numeric)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on `crypto_transactions` table
    - Add policies for authenticated users to manage their own transactions
*/

CREATE TABLE IF NOT EXISTS crypto_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  crypto_name text NOT NULL,
  quantity numeric NOT NULL,
  purchase_price numeric NOT NULL,
  total_value numeric NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE crypto_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own transactions"
  ON crypto_transactions
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own transactions"
  ON crypto_transactions
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);