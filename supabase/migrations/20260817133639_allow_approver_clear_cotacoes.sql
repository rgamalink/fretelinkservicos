-- Permite que o aprovador limpe todas as cotações submetidas/decididas
-- (usado pelo botão "Limpar Tudo", para reiniciar testes). O DELETE em
-- cotacoes_aprovacao propaga para cotacoes_status via ON DELETE CASCADE.

GRANT DELETE ON public.cotacoes_aprovacao TO authenticated;

DROP POLICY IF EXISTS "Approver can delete submissions" ON public.cotacoes_aprovacao;
CREATE POLICY "Approver can delete submissions"
ON public.cotacoes_aprovacao FOR DELETE TO authenticated
USING (private.has_role(auth.uid(), 'approver'::public.app_role));
