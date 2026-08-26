-- Permite que um administrador (role 'approver' em user_roles) veja e
-- gerencie o perfil de qualquer usuário pela tela de Configuração.

DROP POLICY IF EXISTS "Approver can view all roles" ON public.user_roles;
CREATE POLICY "Approver can view all roles" ON public.user_roles FOR SELECT TO authenticated
USING (private.has_role(auth.uid(), 'approver'::app_role));

-- Promove/rebaixa um usuário concedendo ou revogando a role 'approver' em
-- user_roles — a mesma tabela usada por private.has_role() em todo o
-- controle de acesso já existente (aprovação de cotações, ver todos os
-- cadastros etc.), então uma promoção aqui já propaga permissões reais.
-- O e-mail fixo (rodrigo.gama@linkbr.com) nunca pode ser alterado.
CREATE OR REPLACE FUNCTION public.admin_set_user_role(target_id uuid, new_role text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT private.has_role(auth.uid(), 'approver'::app_role) THEN
    RAISE EXCEPTION 'Apenas administradores podem alterar perfis.';
  END IF;
  IF new_role NOT IN ('administrador', 'usuario') THEN
    RAISE EXCEPTION 'Perfil inválido: %', new_role;
  END IF;
  IF EXISTS (
    SELECT 1 FROM auth.users WHERE id = target_id AND lower(email) = 'rodrigo.gama@linkbr.com'
  ) THEN
    RAISE EXCEPTION 'O perfil de rodrigo.gama@linkbr.com não pode ser alterado.';
  END IF;

  IF new_role = 'administrador' THEN
    INSERT INTO public.user_roles (user_id, role)
    VALUES (target_id, 'approver'::app_role)
    ON CONFLICT (user_id, role) DO NOTHING;
  ELSE
    DELETE FROM public.user_roles WHERE user_id = target_id AND role = 'approver'::app_role;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_set_user_role(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_set_user_role(uuid, text) TO authenticated;

-- Remove apenas o cadastro (profiles + eventuais roles) — não apaga a conta
-- de login em auth.users, então a pessoa continua conseguindo entrar e
-- volta a aparecer como pendente. Nunca permite apagar a si mesmo nem o
-- e-mail fixo, para não travar o acesso de administração.
CREATE OR REPLACE FUNCTION public.admin_excluir_usuario(target_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT private.has_role(auth.uid(), 'approver'::app_role) THEN
    RAISE EXCEPTION 'Apenas administradores podem excluir cadastros.';
  END IF;
  IF target_id = auth.uid() THEN
    RAISE EXCEPTION 'Você não pode excluir seu próprio cadastro.';
  END IF;
  IF EXISTS (
    SELECT 1 FROM auth.users WHERE id = target_id AND lower(email) = 'rodrigo.gama@linkbr.com'
  ) THEN
    RAISE EXCEPTION 'O cadastro de rodrigo.gama@linkbr.com não pode ser excluído.';
  END IF;

  DELETE FROM public.user_roles WHERE user_id = target_id;
  DELETE FROM public.profiles WHERE id = target_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_excluir_usuario(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_excluir_usuario(uuid) TO authenticated;
