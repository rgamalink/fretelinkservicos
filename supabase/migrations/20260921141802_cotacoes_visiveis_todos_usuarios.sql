-- Todas as cotações salvas/submetidas devem ficar visíveis para todos os
-- usuários autenticados, independente do perfil (aprovador ou usuário
-- comum). Antes, um usuário comum só enxergava suas próprias submissões
-- (auth.uid() = user_id) e apenas o aprovador via todas.

DROP POLICY IF EXISTS "Users can view their own submissions" ON public.cotacoes_aprovacao;
DROP POLICY IF EXISTS "Approver can view all submissions" ON public.cotacoes_aprovacao;

CREATE POLICY "Authenticated users can view all submissions"
ON public.cotacoes_aprovacao FOR SELECT TO authenticated
USING (true);
