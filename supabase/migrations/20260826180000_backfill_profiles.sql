-- O gatilho public.handle_new_user() só popula profiles em INSERT novo em
-- auth.users. Qualquer conta criada antes desse gatilho existir nunca
-- ganhou uma linha em profiles, então ela nunca aparece na tela de
-- Configuração/Aprovação de Logins — mesmo sendo um cadastro válido e já
-- usado para login. Preenche as linhas que faltam para todos os usuários
-- já existentes em auth.users.
INSERT INTO public.profiles (id, full_name, company, email, access_status)
SELECT
  u.id,
  u.raw_user_meta_data ->> 'full_name',
  u.raw_user_meta_data ->> 'company',
  u.email,
  CASE WHEN lower(u.email) = 'rodrigo.gama@linkbr.com' THEN 'aprovado' ELSE 'pendente' END
FROM auth.users u
WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id)
ON CONFLICT (id) DO NOTHING;
