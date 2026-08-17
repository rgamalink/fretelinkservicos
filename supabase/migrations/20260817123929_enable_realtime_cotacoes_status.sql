-- Habilita Realtime em cotacoes_status para que decisões de aprovação/reprovação
-- sejam replicadas ao vivo em todas as telas (Cotações Salvas, painel principal,
-- Cotações Submetidas à Aprovação), sem precisar recarregar a página.

ALTER TABLE public.cotacoes_status REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'cotacoes_status'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.cotacoes_status;
  END IF;
END $$;
